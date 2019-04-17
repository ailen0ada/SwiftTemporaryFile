/* *************************************************************************************************
 TemporaryFile.swift
   © 2017-2019 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation

#if canImport(ObjectiveC)
import FileHandleHandle
public typealias FileHandle_ = _FileHandleHandle
#else
public typealias FileHandle_ = FileHandle
#endif

private func _unavailable(_ function:StaticString = #function) -> Never {
  fatalError("\(function) is unavailable in TemporaryFile.")
}

/// # TemporaryFile
///
/// Subclass of `FileHandle`.
/// Represents a temporary file.
public final class TemporaryFile: FileHandle_ {
  private var _url: URL!
  
  #if canImport(ObjectiveC)
  private var _fileHandle: FileHandle! { return super.__fileHandle }
  #else
  private var _fileHandle: FileHandle!
  #endif
  
  public private(set) var isClosed: Bool = false
  
  internal weak var _temporaryDirectory: TemporaryDirectory!
  
  /// Use the file at `url` temporarily.
  internal init?(fileAt url:URL) {
    guard url.isExistingLocalFileURL else { return nil }
    guard let fh = try? FileHandle(forUpdating:url) else { return nil }
    
    #if canImport(ObjectiveC)
    super.init(fileHandle: fh)
    #else
    super.init(fileDescriptor:fh.fileDescriptor, closeOnDealloc: false)
    self._fileHandle = fh
    #endif
    
    self._url = url
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  public override func isEqual(_ object: Any?) -> Bool {
    guard case let anotherTmpFile as TemporaryFile = object else { return false }
    return self._fileHandle.isEqual(anotherTmpFile._fileHandle)
  }
  
  public override var hash: Int {
    return self._fileHandle.hash
  }
  
  /// Just close and remove
  internal func _close() -> Bool {
    if self.isClosed { return false }
    
    self._fileHandle.closeFile()
    self.isClosed = true
    
    guard let _ = try? FileManager.default.removeItem(at:self._url) else {
      return false
    }
    return true
  }
  
  public override var availableData: Data {
    return self._fileHandle.availableData
  }
  
  public override func closeFile() {
    _ = self._temporaryDirectory._close(temporaryFile:self)
  }
  
  @available(*, unavailable, message: "You can't get the file descriptor of TemporaryFile.")
  public override var fileDescriptor: Int32 { _unavailable() }
  
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
  
  public override func seek(toFileOffset offset: UInt64) {
    self._fileHandle.seek(toFileOffset:offset)
  }
  
  public override func seekToEndOfFile() -> UInt64 {
    return self._fileHandle.seekToEndOfFile()
  }
  
  public override func synchronizeFile() {
    self._fileHandle.synchronizeFile()
  }
  
  public override func truncateFile(atOffset offset: UInt64) {
    return self._fileHandle.truncateFile(atOffset:offset)
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

fileprivate protocol _TemporaryFile {}
extension _TemporaryFile where Self: TemporaryFile {
  fileprivate init(_in temporaryDirectory:TemporaryDirectory,
                   prefix:String, suffix: String, contents data:Data?)
  {
    self = temporaryDirectory._newTemporaryFile(prefix:prefix, suffix:suffix, contents:data) as! Self
  }
}

extension TemporaryFile: _TemporaryFile {
  /// Create a temporary file in `temporaryDirectory`.
  /// The filename will be "prefix[random string]suffix".
  public convenience init(in temporaryDirectory:TemporaryDirectory = .default,
                          prefix:String = "", suffix: String = "", contents data:Data? = nil)
  {
    self.init(_in:temporaryDirectory, prefix:prefix, suffix:suffix, contents:data)
  }
}

extension TemporaryFile {
  /// Create a temporary file and execute the closure passing the temporary file as an argument.
  @discardableResult
  public convenience init(_ body:(TemporaryFile) throws -> Void) rethrows {
    self.init()
    defer { self.closeFile() }
    try body(self)
  }
}

extension TemporaryFile {
  /// Copy the file to `destination` at which to place the copy of it.
  /// This method calls `FileManager.copyItem(at:to:) throws` internally.
  /// - returns: `true` if the file is copied successfully, otherwise `false`.
  @discardableResult public func copy(to destination:URL) -> Bool {
    return (try? FileManager.default.copyItem(at:self._url, to:destination)) != nil
  }
}
