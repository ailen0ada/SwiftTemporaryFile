/* *************************************************************************************************
 TemporaryFileProtocol.swift
   © 2020 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation
import yProtocols

/// A type that represents some temporary file.
public protocol TemporaryFileProtocol: FileHandleProtocol,
                                       TextOutputStream,
                                       Hashable {
  /// Write the data containing a representation of the String encoded using a given encoding.
  /// See also `String.data(string:using:allowLossyConversion:)` for the details about parameters.
  mutating func write(string: String, using encoding: String.Encoding, allowLossyConversion: Bool) throws
}

extension TemporaryFileProtocol {
  public mutating func write(string: String, using encoding: String.Encoding = .utf8, allowLossyConversion: Bool = false) throws {
    guard let data = string.data(using: encoding, allowLossyConversion: allowLossyConversion) else {
      throw TemporaryFileError.stringConversionFailed
    }
    try self.write(contentsOf: data)
  }
  
  /// Write `string` to the instance using `mutating func write(string:) throws` of `TemporaryFileProtocol`.
  /// `string` will be converted to an instance of `Data` using UTF-8 encoding.
  /// Runtime error occurs when writing method throws an error or `string` cannot be converted.
  public mutating func write(_ string: String) {
    try! self.write(string: string, using: .utf8, allowLossyConversion: false)
  }
}
