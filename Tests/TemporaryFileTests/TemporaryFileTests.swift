/* *************************************************************************************************
 TemporaryFileTests.swift
   © 2018-2019 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import XCTest
@testable import TemporaryFile

import Foundation

final class TemporaryFileTests: XCTestCase {
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
    
    let destination = URL.temporaryDirectory.appendingPathComponent(
        "jp.YOCKOW.TemporaryFile.test." + UUID().base32EncodedString(),
        isDirectory:false
    )
    
    tmpFile.copy(to:destination)
    
    let copied = try! FileHandle(forReadingFrom:destination)
    defer { copied.closeFile() }
    
    XCTAssertEqual(copied.availableData, data)
    
    try! FileManager.default.removeItem(at:destination)
  }
  
  func test_temporaryFile_truncate() {
    let data = "Hello!".data(using:.utf8)!
    let tmpFile = TemporaryFile(contents:data)
    
    tmpFile.write(data)
    tmpFile.seek(toFileOffset:0)
    XCTAssertEqual(tmpFile.availableData, data)
    
    tmpFile.truncateFile(atOffset:5)
    tmpFile.seek(toFileOffset:0)
    XCTAssertEqual(String(data:tmpFile.availableData, encoding:.utf8), "Hello")
  }
}

