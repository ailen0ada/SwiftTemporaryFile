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
                                       DataOutputStream,
                                       TextOutputStream,
                                       Hashable {
}

extension TemporaryFileProtocol {
  /// Write `data` to the instance using `mutating func write(contentsOf:) throws` of `FileHandleProtocol`.
  /// Runtime error occurs when that method throws an error.
  public mutating func write<D>(_ data: D) where D: DataProtocol {
    try! self.write(contentsOf: data)
  }
  
  /// Write `string` to the instance using `mutating func write(contentsOf:) throws` of `FileHandleProtocol`.
  /// `string` will be converted to an instance of `Data` using UTF-8 encoding.
  /// Runtime error occurs when writing method throws an error or `string` cannot be converted.
  public mutating func write(_ string: String) {
    guard let data = string.data(using: .utf8) else {
      fatalError("\(#function): Failed to convert `string` to an instance of `Data`.")
    }
    try! self.write(contentsOf: data)
  }
}
