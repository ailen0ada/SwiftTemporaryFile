/* *************************************************************************************************
 UUID+Base32.swift
   © 2018 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation

private let _scalars: [Unicode.Scalar] = [
  "A", "B", "C", "D", "E", "F", "G", "H",
  "I", "J", "K", "L", "M", "N", "O", "P",
  "Q", "R", "S", "T", "U", "V", "W", "X",
  "Y", "Z", "2", "3", "4", "5", "6", "7"
]

extension Array {
  fileprivate subscript(_ uint8:UInt8) -> Element { return self[Int(uint8)] }
}

extension UUID {
  internal var _uuidStringForFilename: String {
    // Base32 without padding
    // * uuid is 128bit-wide (16 bytes).
    var scalars = String.UnicodeScalarView()
    var uuid:uuid_t = self.uuid
    withUnsafeBytes(of:&uuid) { uuid_p in
      for ii in 0...2 {
        let bytes = (
          uuid_p[ii * 5],
          uuid_p[ii * 5 + 1],
          uuid_p[ii * 5 + 2],
          uuid_p[ii * 5 + 3],
          uuid_p[ii * 5 + 4]
        )
        // aaaaaaaa bbbbbbbb cccccccc dddddddd eeeeeeee
        // -> aaaaa aaabb bbbbb bcccc ccccd ddddd ddeee eeeee
        
        scalars.append(_scalars[bytes.0 >> 3])
        scalars.append(_scalars[((bytes.0 & 0b00000111) << 2) | (bytes.1 >> 6)])
        scalars.append(_scalars[(bytes.1 & 0b00111110) >> 1])
        scalars.append(_scalars[((bytes.1 & 0b00000001) << 4) | (bytes.2 >> 4)])
        scalars.append(_scalars[((bytes.2 & 0b00001111) << 1) | (bytes.3 >> 7)])
        scalars.append(_scalars[(bytes.3 & 0b01111100) >> 2])
        scalars.append(_scalars[((bytes.3 & 0b00000011) << 3) | (bytes.4 >> 5)])
        scalars.append(_scalars[bytes.4 & 0b00011111])
      }
      
      // The last byte
      scalars.append(_scalars[uuid_p[15] >> 3])
      scalars.append(_scalars[(uuid_p[15] & 0b00000111) << 2])
    }
    return String(scalars)
  }
}
