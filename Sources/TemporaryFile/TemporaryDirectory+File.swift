/* *************************************************************************************************
 TemporaryDirectory+File.swift
   © 2018-2020 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
import Foundation
import yExtensions
import yProtocols

private let manager = FileManager.default

public typealias TemporaryFile = TemporaryDirectory.File

/// # TemporaryDirectory
///
/// Represents a temporary directory.
public final class TemporaryDirectory {
  /// Represents a temporary file.
  /// The file is created always in some temporary directory represented by `TemporaryDirectory`.
  public final class File: FileHandleProtocol, Hashable {
    public private(set) var isClosed: Bool = false
    private var _url: URL
    internal private(set) var _fileHandle: FileHandle
    private unowned var _temporaryDirectory: TemporaryDirectory
    
    public static func ==(lhs: File, rhs: File) -> Bool {
      return lhs._url == rhs._url
    }
    
    public func hash(into hasher: inout Hasher) {
      hasher.combine(self._url)
    }
    
    fileprivate init(_fileAt url: URL, temporaryDirectory: TemporaryDirectory) throws {
      assert(url.isExistingLocalFile, "File doesn't exist at \(url.absoluteString)")
      let fh = try FileHandle(forUpdating: url)
      self._url = url
      self._fileHandle = fh
      self._temporaryDirectory = temporaryDirectory
    }
    
    /// Just close and remove
    fileprivate func _close() throws {
      if self.isClosed { throw TemporaryFileError.alreadyClosed }
      try self._fileHandle.close()
      self.isClosed = true
      try FileManager.default.removeItem(at: self._url)
    }
    
    public func close() throws {
      try self._close()
      let removed = self._temporaryDirectory._temporaryFiles.remove(self)
      assert(removed == self)
    }
    
    public func offset() throws -> UInt64 {
      return try self._fileHandle.offset()
    }
    
    public func read(upToCount count: Int) throws -> Data? {
      return try self._fileHandle.read(upToCount: count)
    }
    
    public func seek(toOffset offset: UInt64) throws {
      try self._fileHandle.seek(toOffset: offset)
    }
    
    @discardableResult
    public func seekToEnd() throws -> UInt64 {
      return try self._fileHandle.seekToEnd()
    }
    
    public func synchronize() throws {
      try self._fileHandle.synchronize()
    }
    
    public func truncate(atOffset offset: UInt64) throws {
      try self._fileHandle.truncate(atOffset: offset)
    }
    
    public func write<T>(contentsOf data: T) throws where T : DataProtocol {
      try self._fileHandle.write(contentsOf: data)
    }
  }
  
  public private(set) var isClosed: Bool
  internal var _url:URL // testable
  private var _temporaryFiles: Set<File>
  
  /// Use the directory at `url` temporarily.
  private init(_directoryAt url:URL) {
    assert(url.isExistingLocalDirectory, "Directory doesn't exist at \(url.absoluteString)")
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
    guard parent.isExistingLocalDirectory else { throw TemporaryFileError.invalidURL }
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

