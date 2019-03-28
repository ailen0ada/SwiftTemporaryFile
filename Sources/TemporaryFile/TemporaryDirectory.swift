/* *************************************************************************************************
 TemporaryDirectory.swift
   © 2018 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
import Foundation
private let manager = FileManager.default

/// # TemporaryDirectory
///
/// Represents a temporary directory.
public final class TemporaryDirectory {
  internal var _url:URL
  public private(set) var isClosed: Bool
  
  private var _temporaryFiles: Set<TemporaryFile>
  
  /// Use the directory at `url` temporarily.
  internal init?(directoryAt url:URL) {
    guard url.isExistingLocalDirectoryURL else { return nil }
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
    inParentDirectoryAt url:URL = .temporaryDirectory,
    prefix:String = "jp.YOCKOW.TemporaryFile/",
    suffix:String = ".\(ProcessInfo.processInfo.processIdentifier)"
  ) {
    let parent = url.resolvingSymlinksInPath()
    precondition(parent.isExistingLocalDirectoryURL,
                 "\(parent.path) is not a directory or does not exist.")
    
    let uuid = UUID()._uuidStringForFilename
    let tmpDirURL = parent.appendingPathComponent("\(prefix)\(uuid)\(suffix)", isDirectory:true)
    
    try! manager.createDirectory(at:tmpDirURL,
                                 withIntermediateDirectories:true,
                                 attributes:[.posixPermissions:NSNumber(value:Int16(0o700))])
    
    self.init(directoryAt:tmpDirURL)!
  }
  
  /// Create a temporary file in the temporary directory represented by the receiver.
  internal func _newTemporaryFile(prefix:String , suffix:String, contents data:Data?)
    -> TemporaryFile
  {
    if self.isClosed { fatalError("The temporary directory is already closed.") }
    let filename = prefix + UUID()._uuidStringForFilename + suffix
    let url = self._url.appendingPathComponent(filename, isDirectory:false)
    guard manager.createFile(atPath:url.path, contents:data,
                             attributes:[.posixPermissions:NSNumber(value:Int16(0o600))])
    else {
      fatalError("Failed to create a temporary file at \(url.path)")
    }
    
    let tmpFile = TemporaryFile(fileAt:url)!
    self._temporaryFiles.insert(tmpFile)
    return tmpFile
  }
  
  /// Close `temporaryFile` and remove it from the list.
  internal func _close(temporaryFile:TemporaryFile) -> Bool {
    guard let removed = self._temporaryFiles.remove(temporaryFile) else { return false }
    return removed._close()
  }
  
  /// Remove all temporary files in the temporary directory represented by the receiver.
  /// - returns: `true` if all files are removed successfully, otherwise `false`.
  @discardableResult public func removeAllTemporaryFiles() -> Bool {
    var result: UInt8 = 1
    while self._temporaryFiles.count > 0 {
      let file = self._temporaryFiles.first!
      // `file` will be removed from `_temporaryFiles` in this method.
      result *= self._close(temporaryFile:file) ? 1 : 0
    }
    return result > 0 ? true : false
  }
  
  /// Close the temporary directory represented by the receiver.
  /// All of the temporary files in the temporary directory will be removed.
  /// The directory itself will be also removed if the directory is empty.
  /// - returns: `true` if the directory is removed successfully, otherwise `false`.
  @discardableResult public func close() -> Bool {
    if self.isClosed { return false }
    
    guard self.removeAllTemporaryFiles() else { return false }
    guard let _ = try? manager.removeItem(at:self._url) else { return false }
    self.isClosed = true
    return true
  }
  
  deinit {
    self.close()
  }
}

extension TemporaryDirectory: Hashable {
  public static func == (lhs:TemporaryDirectory, rhs:TemporaryDirectory) -> Bool {
    return lhs._url.path == rhs._url.path
  }
  
  #if compiler(>=4.2)
  public func hash(into hasher:inout Hasher) {
    hasher.combine(self._url.path)
  }
  #else
  public var hashValue: Int {
    return self._url.path.hashValue
  }
  #endif
}

private func _clean() {
  TemporaryDirectory._default = nil
}

extension TemporaryDirectory {
  fileprivate static var _default: TemporaryDirectory? = nil
  
  /// The default temporary directory.
  public static var `default`: TemporaryDirectory {
    if _default == nil {
      _default = TemporaryDirectory()
      atexit(_clean)
    }
    return _default!
  }
}

