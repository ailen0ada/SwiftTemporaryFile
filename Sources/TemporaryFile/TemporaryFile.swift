/* *************************************************************************************************
 TemporaryFile.swift
   © 2017-2018 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation

/// # TemporaryFile
///
/// Represents a temporary file.
public final class TemporaryFile {
  private var _fileHandle: FileHandle
  private var _url: URL
  public private(set) var isClosed: Bool
  
  fileprivate weak var _temporaryDirectory: TemporaryDirectory!
  
  /// Use the file at `url` temporarily.
  internal init?(fileAt url:URL) {
    guard url.isExistingLocalFileURL else { return nil }
    guard let fh = try? FileHandle(forUpdating:url) else { return nil }
    self._fileHandle = fh
    self._url = url
    self.isClosed = false
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
  
  /// Close the temporary file represented by the receiver.
  @discardableResult public func close() -> Bool {
    return self._temporaryDirectory._close(temporaryFile:self)
  }
}

extension TemporaryFile: Hashable {
  public static func == (lhs: TemporaryFile, rhs: TemporaryFile) -> Bool {
    return lhs._fileHandle == rhs._fileHandle
  }

  #if swift(>=4.2)
  public func hash(into hasher:inout Hasher) {
    hasher.combine(self._fileHandle)
  }
  #else
  public var hashValue: Int {
    return self._fileHandle.hashValue
  }
  #endif
}


fileprivate protocol _TemporaryFile {}
extension _TemporaryFile where Self: TemporaryFile {
  fileprivate init(_in temporaryDirectory:TemporaryDirectory,
                   prefix:String, suffix: String, contents data:Data?)
  {
    self = temporaryDirectory._newTemporaryFile(prefix:prefix, suffix:suffix, contents:data) as! Self
    self._temporaryDirectory = temporaryDirectory
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
    defer { self.close() }
    try body(self)
  }
}

// like FileHandle...
extension TemporaryFile {
  public var availableData: Data {
    return self._fileHandle.availableData
  }
  
  public var offsetInFile: UInt64 {
    return self._fileHandle.offsetInFile
  }
  
  public func readData(ofLength length: Int) -> Data {
    return self._fileHandle.readData(ofLength:length)
  }
  
  public func readDataToEndOfFile() -> Data {
    return self._fileHandle.readDataToEndOfFile()
  }
  
  public func seek(toFileOffset offset: UInt64) {
    self._fileHandle.seek(toFileOffset:offset)
  }
  
  public func seekToEndOfFile() -> UInt64 {
    return self._fileHandle.seekToEndOfFile()
  }
  
  public func truncateFile(atOffset offset: UInt64) {
    /// Workaround for [SR-6524](https://bugs.swift.org/browse/SR-6524)
    #if swift(>=4.1.50) || !os(Linux)
    self._fileHandle.truncateFile(atOffset:offset)
    #else
    lseek(self._fileHandle.fileDescriptor, off_t(offset), SEEK_SET)
    ftruncate(self._fileHandle.fileDescriptor, off_t(offset))
    #endif
  }
  
  public func write(_ data: Data) {
    self._fileHandle.write(data)
  }
}

extension TemporaryFile {
  /// Copy the file to `destination` at which to place the copy of it.
  /// This method calls `FileManager.copyItem(at:to:) throws` internally.
  /// - returns: `true` if the file is copied successfully, otherwise `false`.
  @discardableResult public func copy(to destination:URL) -> Bool {
    if let _ = try? FileManager.default.copyItem(at:self._url, to:destination) {
      return true
    } else {
      return false
    }
  }
}

