/* *************************************************************************************************
 TemporaryDirectory+File.swift
   © 2018-2019 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
import Foundation
import yExtensions
private let manager = FileManager.default

public typealias TemporaryFile = TemporaryDirectory.File

/// # TemporaryDirectory
///
/// Represents a temporary directory.
public final class TemporaryDirectory {
  /// Represents a temporary file.
  /// The file is created always in some temporary directory represented by `TemporaryDirectory`.
  public final class File: FileHandle_ {
    public private(set) var isClosed: Bool = false
    private var _url: URL
    private var _fileHandle: FileHandle
    private unowned var _temporaryDirectory: TemporaryDirectory
    
    fileprivate init(_fileAt url: URL, temporaryDirectory: TemporaryDirectory) throws {
      assert(url.isExistingLocalFileURL, "File doesn't exist at \(url.absoluteString)")
      let fh = try FileHandle(forUpdating: url)
      self._url = url
      self._fileHandle = fh
      self._temporaryDirectory = temporaryDirectory
      #if canImport(ObjectiveC)
      super.init()
      #else
      super.init(fileDescriptor: fh.fileDescriptor, closeOnDealloc: false)
      #endif
    }
    
    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
      guard case let anotherTmpFile as File = object else { return false }
      return self._fileHandle.isEqual(anotherTmpFile._fileHandle)
    }
    
    public override var hash: Int {
      return self._fileHandle.hash
    }
    
    /// Just close and remove
    fileprivate func _close() throws {
      if self.isClosed { throw TemporaryFileError.alreadyClosed }
      
      func __close(fh: FileHandle) throws {
        #if swift(>=5.0)
        if  #available(macOS 10.15, *) {
          try fh.close()
          return
        }
        #endif
        fh.closeFile()
      }
      try __close(fh: self._fileHandle)
      self.isClosed = true
      try FileManager.default.removeItem(at: self._url)
    }
    
    public override var availableData: Data {
      return self._fileHandle.availableData
    }
    
    public override func close() throws {
      try self._close()
      let removed = self._temporaryDirectory._temporaryFiles.remove(self)
      assert(removed == self)
    }
    
    @available(*, deprecated, renamed: "close", message: "Use `func close() throws` instead.")
    public override func closeFile() {
      try? self.close()
    }
    
    @available(*, unavailable, message: "You can't get the file descriptor of TemporaryFile.")
    public override var fileDescriptor: Int32 {
      return self._fileHandle.fileDescriptor
    }
    
    public override var offsetInFile: UInt64 {
      return self._fileHandle.offsetInFile
    }
    
    private var _readabilityHandler: ((FileHandle) -> Void)? = nil
    public override var readabilityHandler: ((FileHandle) -> Void)? {
      get {
        return self._readabilityHandler
      }
      set {
        if let handler = newValue {
          self._fileHandle.readabilityHandler = {[unowned self] _ in
            handler(self)
          }
        } else {
          self._fileHandle.readabilityHandler = nil
          self._readabilityHandler = nil
        }
      }
    }
    
    public override func readData(ofLength length: Int) -> Data {
      return self._fileHandle.readData(ofLength:length)
    }
    
    public override func readDataToEndOfFile() -> Data {
      return self._fileHandle.readDataToEndOfFile()
    }
    
    @available(*, deprecated, renamed: "seek(toOffset:)", message: "Use `func seek(toOffset offset: UInt64) throws` instead.")
    public override func seek(toFileOffset offset: UInt64) {
      try! self.seek(toOffset: offset)
    }
    
    public override func seek(toOffset offset: UInt64) throws {
      #if swift(>=5.0)
      if #available(macOS 10.15, *) {
        try self._fileHandle.seek(toOffset: offset)
        return
      }
      #endif
      self._fileHandle.seek(toFileOffset: offset)
    }
    
    public override func seekToEndOfFile() -> UInt64 {
      return self._fileHandle.seekToEndOfFile()
    }
    
    public override func synchronize() throws {
      #if swift(>=5.0)
      if #available(macOS 10.15, *) {
        try self._fileHandle.synchronize()
        return
      }
      #endif
      self._fileHandle.synchronizeFile()
    }
    
    @available(*, deprecated, message: "Use `func synchronize() throws` instead.")
    public override func synchronizeFile() {
      try? self.synchronize()
    }
    
    public override func truncate(atOffset offset: UInt64) throws {
      #if swift(>=5.0)
      if #available(macOS 10.15, *) {
        try self._fileHandle.truncate(atOffset: offset)
        return
      }
      #endif
      self._fileHandle.truncateFile(atOffset: offset)
    }
    
    @available(*, deprecated, renamed: "truncate(atOffset:)", message: "Use `func truncate(atOffset offset: UInt64) throws` instead.")
    public override func truncateFile(atOffset offset: UInt64) {
      try? self.truncate(atOffset: offset)
    }
    
    private var _writeabilityHandler: ((FileHandle) -> Void)? = nil
    public override var writeabilityHandler: ((FileHandle) -> Void)? {
      get {
        return self._writeabilityHandler
      }
      set {
        if let handler = newValue {
          self._fileHandle.writeabilityHandler = {[unowned self] _ in
            handler(self)
          }
        } else {
          self._fileHandle.writeabilityHandler = nil
          self._writeabilityHandler = nil
        }
      }
    }
    
    public override func write(_ data: Data) {
      self._fileHandle.write(data)
    }
  }
  
  public private(set) var isClosed: Bool
  internal var _url:URL // testable
  private var _temporaryFiles: Set<File>
  
  /// Use the directory at `url` temporarily.
  private init(_directoryAt url:URL) {
    assert(url.isExistingLocalDirectoryURL, "Directory doesn't exist at \(url.absoluteString)")
    self._url = url
    self.isClosed = false
    self._temporaryFiles = []
  }
  
  /// Create a temporary directory. The path to the temporary directory will be
  /// "/path/to/parentDirectory/prefix[random string]suffix".
  /// - parameter url: The path to the directory that will contain the temporary directory.
  /// - parameter prefix: The prefix of the name of the temporary directory.
  /// - parameter suffix: The suffix of the name of the temporary directory.
  public convenience init(
    in parentDirectory: URL = .temporaryDirectory,
    prefix: String = "jp.YOCKOW.TemporaryFile",
    suffix: String = ".\(String(ProcessInfo.processInfo.processIdentifier, radix: 10))"
  ) throws {
    let parent = parentDirectory.resolvingSymlinksInPath()
    guard parent.isExistingLocalDirectoryURL else { throw TemporaryFileError.invalidURL }
    let uuid = UUID().base32EncodedString()
    let tmpDirURL = parent.appendingPathComponent("\(prefix)\(uuid)\(suffix)", isDirectory: true)
    try manager.createDirectory(at: tmpDirURL,
                                withIntermediateDirectories: true,
                                attributes: [.posixPermissions: NSNumber(value: Int16(0o700))])
    self.init(_directoryAt: tmpDirURL)
  }
  
  @available(*, deprecated, renamed: "init(in:prefix:suffix:)")
  public convenience init(
    inParentDirectoryAt url:URL,
    prefix:String = "jp.YOCKOW.TemporaryFile/",
    suffix:String = ".\(ProcessInfo.processInfo.processIdentifier)"
  ) {
    try! self.init(in: url, prefix: prefix, suffix: suffix)
  }
  
  /// Create a temporary file in the temporary directory represented by the receiver.
  internal func _newTemporaryFile(prefix: String,
                                  suffix: String,
                                  contents data: Data?) throws -> TemporaryFile
  {
    if self.isClosed { throw TemporaryFileError.alreadyClosed }
    let filename = prefix + UUID().base32EncodedString() + suffix
    let url = self._url.appendingPathComponent(filename, isDirectory: false)
    
    func _createFile(at url: URL, contents data: Data?) -> Bool {
      return manager.createFile(atPath: url.path, contents: data,
                                attributes: [.posixPermissions: NSNumber(value: Int16(0o600))])
    }
    guard _createFile(at: url, contents: data) else { throw TemporaryFileError.fileCreationFailed }

    let tmpFile = try TemporaryFile(_fileAt: url, temporaryDirectory: self)
    self._temporaryFiles.insert(tmpFile)
    return tmpFile
  }
  /// Remove all temporary files in the temporary directory represented by the receiver.
  /// - returns: `true` if all files are removed successfully, otherwise `false`.
  public func closeAllTemporaryFiles() throws {
    while self._temporaryFiles.count > 0 {
      let file = self._temporaryFiles.first!
      // `file` will be removed from `_temporaryFiles` in this method.
      try file.close()
    }
  }
  
  @available(*, deprecated, renamed: "closeAllTemporaryFiles()")
  @discardableResult public func removeAllTemporaryFiles() -> Bool {
    do {
      try self.closeAllTemporaryFiles()
    } catch {
      return false
    }
    return true
  }

  /// Close the temporary directory represented by the receiver.
  /// All of the temporary files in the temporary directory will be removed.
  /// The directory itself will be also removed if the directory is empty.
  public func close() throws {
    if self.isClosed { throw TemporaryFileError.alreadyClosed }
    try self.closeAllTemporaryFiles()
    try manager.removeItem(at: self._url)
    self.isClosed = true
  }

  deinit {
    try? self.close()
  }
}


private func _clean() {
  try? TemporaryDirectory._default.close()
  TemporaryDirectory._default = nil
}
extension TemporaryDirectory {
  fileprivate static var _default: TemporaryDirectory! = nil

  /// The default temporary directory.
  public static var `default`: TemporaryDirectory {
    if _default == nil {
      _default = try! TemporaryDirectory()
      atexit(_clean)
    }
    return _default
  }
}

extension TemporaryDirectory: Hashable {
  public static func ==(lhs: TemporaryDirectory, rhs: TemporaryDirectory) -> Bool {
    return lhs._url.path == rhs._url.path
  }
  public func hash(into hasher: inout Hasher) {
    hasher.combine(self._url.path)
  }
}

private protocol _TemporaryFile {}
extension _TemporaryFile where Self: TemporaryFile {
  fileprivate init(_in temporaryDirectory: TemporaryDirectory, prefix: String, suffix: String, contents data: Data?) throws {
    self = try temporaryDirectory._newTemporaryFile(prefix: prefix, suffix: suffix, contents: data) as! Self
  }
}

extension TemporaryDirectory.File: _TemporaryFile {
  /// Create a temporary file in `temporaryDirectory`.
  /// The filename will be "prefix[random string]suffix".
  public convenience init(in temporaryDirectory: TemporaryDirectory = .default,
                          prefix:String = "", suffix: String = "", contents data:Data? = nil) throws
  {
    try self.init(_in: temporaryDirectory, prefix :prefix, suffix: suffix, contents: data)
  }
}

extension TemporaryDirectory.File {
  /// Create a temporary file and execute the closure passing the temporary file as an argument.
  @discardableResult
  public convenience init(_ body: (TemporaryFile) throws -> Void) rethrows {
    try! self.init()
    defer { try? self.close() }
    try body(self)
  }
}

extension TemporaryDirectory.File {
  /// Copy the file to `destination` at which to place the copy of it.
  /// This method calls `FileManager.copyItem(at:to:) throws` internally.
  public func copy(to destination:URL) throws {
    try FileManager.default.copyItem(at: self._url, to: destination)
  }
}


