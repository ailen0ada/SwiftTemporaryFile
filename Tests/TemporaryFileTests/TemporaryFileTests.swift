/* *************************************************************************************************
 TemporaryFileTests.swift
   © 2018 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import XCTest
@testable import TemporaryFile

import Foundation

final class TemporaryFileTests: XCTestCase {
  func test_UUID() {
    let uuid0 = UUID(uuidString:"00000000-0000-0000-0000-000000000000")!
    XCTAssertEqual(uuid0._uuidStringForFilename, "AAAAAAAAAAAAAAAAAAAAAAAAAA")
    
    let uuid = UUID(uuidString:"E38399E3-83BC-E382-B9EF-BC93EFBC9221")!
    XCTAssertEqual(uuid._uuidStringForFilename, "4OBZTY4DXTRYFOPPXSJ67PESEE")
  }
  
  func test_temporaryDirectory() {
    let prefix = "jp.YOCKOW.TemporaryFile.test."
    let suffix = ".\(ProcessInfo.processInfo.processIdentifier)"
    let tmpDir = TemporaryDirectory(inParentDirectoryAt:.temporaryDirectory,
                                    prefix:prefix, suffix:suffix)
    
    XCTAssertTrue(tmpDir._url.isExistingLocalDirectoryURL)
    XCTAssertNotEqual(tmpDir.close(), tmpDir._url.isExistingLocalDirectoryURL)
  }
  
  func test_temporaryFile() {
    let expectedString = "Hello!"
    let tmpFile = TemporaryFile(suffix:".txt", contents:expectedString.data(using:.utf8)!)
    let data = tmpFile.availableData
    
    guard let string = String(data:data, encoding:.utf8) else {
      XCTFail("Unexpected data.")
      return
    }
    XCTAssertEqual(expectedString, string)
  }
  
  func test_temporaryFile_closure() {
    let closed = TemporaryFile { (tmpFile:TemporaryFile) -> Void in
      let data = Data([0,1,2,3,4])
      let dataLength = UInt64(data.count)
      
      tmpFile.seek(toFileOffset:0)
      tmpFile.write(data)
      XCTAssertEqual(tmpFile.offsetInFile, dataLength)
      
      tmpFile.seek(toFileOffset:0)
      XCTAssertEqual(tmpFile.availableData, data)
      
      tmpFile.truncateFile(atOffset:0)
      XCTAssertEqual(tmpFile.offsetInFile, 0)
      tmpFile.seek(toFileOffset:0)
      XCTAssertEqual(tmpFile.availableData.count, 0)
    }
    XCTAssertTrue(closed.isClosed)
  }
  
  func test_temporaryFile_copy() {
    let data = Data([0,1,2,3,4])
    let tmpFile = TemporaryFile(contents:data)
    
    let destination = URL.temporaryDirectory.appendingPathComponent("jp.YOCKOW.TemporaryFile.test." + UUID()._uuidStringForFilename,
                                                                    isDirectory:false)
    
    tmpFile.copy(to:destination)
    
    let copied = try! FileHandle(forReadingFrom:destination)
    defer { copied.closeFile() }
    
    XCTAssertEqual(copied.availableData, data)
    
    try! FileManager.default.removeItem(at:destination)
  }
  
  static var allTests = [
    ("test_UUID", test_UUID),
    ("test_temporaryDirectory", test_temporaryDirectory),
    ("test_temporaryFile", test_temporaryFile),
    ("test_temporaryFile_closure", test_temporaryFile_closure),
    ("test_temporaryFile_copy", test_temporaryFile_copy),
  ]
}

