/* *************************************************************************************************
 URL+TemporaryFile.swift
   © 2017-2018 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
 
import Foundation

extension URL {
  /// URL for the temporary directory.
  /// On Darwin, it is for the current user.
  public static var temporaryDirectory: URL {
    #if swift(>=4.1) || !os(Linux)
    if #available(iOS 10.0, macOS 10.12, tvOS 10.0, watchOS 3.0, *) {
      return FileManager.default.temporaryDirectory
    }
    #endif
    return URL(fileURLWithPath:NSTemporaryDirectory(), isDirectory:true)
  }
}

extension FileManager {
  /// Returns whether file exists at `url` and is directory.
  /// Returns `nil` if `url` is not a file URL.
  fileprivate func _fileExists(at url:URL) -> (exists:Bool, isDirectory:Bool)? {
    guard url.isFileURL else { return nil }
    
    var isDir: ObjCBool = false
    guard self.fileExists(atPath:url.path, isDirectory:&isDir) else {
      return (false, false)
    }
    
    #if swift(>=4.1) || !os(Linux)
    return (true, isDir.boolValue)
    #else
    return (true, Bool(isDir))
    #endif
  }
}


extension URL {
  /// Returns `true` if the file that the receiver represents exists and is a directory.
  public var isExistingLocalDirectoryURL: Bool {
    guard let result = FileManager.default._fileExists(at:self) else { return false }
    return result.exists && result.isDirectory
  }
  
  /// Returns `true` if the file that the receiver represents exists and is not a directory.
  public var isExistingLocalFileURL: Bool {
    guard let result = FileManager.default._fileExists(at:self) else { return false }
    return result.exists && !result.isDirectory
  }
}
