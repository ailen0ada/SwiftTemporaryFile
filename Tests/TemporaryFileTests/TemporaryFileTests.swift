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
  func test_temporaryDirectory() throws {
    let tmpDir = try TemporaryDirectory(prefix: "jp.YOCKOW.TemporaryFile.test.")
    XCTAssertTrue(tmpDir._url.isExistingLocalDirectoryURL)
    try tmpDir.close()
    XCTAssertFalse(tmpDir._url.isExistingLocalDirectoryURL)
  }
  
  func test_temporaryFile() throws {
    let expectedString = "Hello!"
    let tmpFile = try TemporaryFile(suffix:".txt", contents: expectedString.data(using: .utf8)!)
    let data = tmpFile.availableData
    
    guard let string = String(data:data, encoding:.utf8) else {
      XCTFail("Unexpected data.")
      return
    }
    XCTAssertEqual(expectedString, string)
  }
  
  func test_temporaryFile_closure() throws {
    let closed = try TemporaryFile { (tmpFile:TemporaryFile) -> Void in
      let data = Data([0,1,2,3,4])
      let dataLength = UInt64(data.count)
      
      try tmpFile.seek(toOffset:0)
      tmpFile.write(data)
      XCTAssertEqual(tmpFile.offsetInFile, dataLength)
      
      try tmpFile.seek(toOffset:0)
      XCTAssertEqual(tmpFile.availableData, data)
      
      try tmpFile.truncate(atOffset:0)
      XCTAssertEqual(tmpFile.offsetInFile, 0)
      try tmpFile.seek(toOffset:0)
      XCTAssertEqual(tmpFile.availableData.count, 0)
    }
    XCTAssertTrue(closed.isClosed)
  }
  
  func test_temporaryFile_copy() throws {
    let data = Data([0,1,2,3,4])
    let tmpFile = try TemporaryFile(contents: data)
    
    let destination = URL.temporaryDirectory.appendingPathComponent(
        "jp.YOCKOW.TemporaryFile.test." + UUID().base32EncodedString(),
        isDirectory:false
    )
    
    try tmpFile.copy(to: destination)
    
    let copied = try FileHandle(forReadingFrom: destination)
    defer {
      if #available(OSX 10.15, *) {
        try? copied.close()
      } else {
        copied.closeFile()
      }
    }
    
    XCTAssertEqual(copied.availableData, data)
    
    try FileManager.default.removeItem(at: destination)
  }
  
  func test_temporaryFile_truncate() throws {
    let data = "Hello!".data(using:.utf8)!
    let tmpFile = try TemporaryFile(contents: data)
    
    tmpFile.write(data)
    try tmpFile.seek(toOffset: 0)
    XCTAssertEqual(tmpFile.availableData, data)
    
    try tmpFile.truncate(atOffset: 5)
    try tmpFile.seek(toOffset: 0)
    XCTAssertEqual(String(data:tmpFile.availableData, encoding:.utf8), "Hello")
  }
  
  func test_inMemoryFile() throws {
    let fhData = InMemoryFile()
    XCTAssertTrue(fhData.isEmpty)
    
    fhData.write(Data([0x00, 0x01, 0x02, 0x03]))
    XCTAssertEqual(fhData.count, 4)
    
    try fhData.seek(toOffset: 2)
    XCTAssertEqual(fhData.availableData, Data([0x02, 0x03]))
    
    try fhData.seek(toOffset: 3)
    fhData.write(Data([0x04, 0x05]))
    try fhData.seek(toOffset: 0)
    XCTAssertEqual(fhData.availableData, Data([0x00, 0x01, 0x02, 0x04, 0x05]))
  }
  
  func test_inMemoryFile_sequence() {
    let fhData = InMemoryFile([0x00, 0x01])
    XCTAssertEqual(fhData.next(), 0x00)
    XCTAssertEqual(fhData.offsetInFile, 1)
    XCTAssertEqual(fhData.next(), 0x01)
    XCTAssertEqual(fhData.offsetInFile, 2)
    XCTAssertEqual(fhData.next(), nil)
  }
  
  func test_inMemoryFile_collection() {
    let fhData = InMemoryFile([0x00, 0x01])
    XCTAssertEqual(fhData[1], 0x01)
  }
  
  func test_inMemoryFile_mutableCollection() {
    var fhData = InMemoryFile([0xFF, 0x00])
    fhData.sort()
    XCTAssertEqual(fhData[0], 0x00)
    XCTAssertEqual(fhData[1], 0xFF)
  }
  
  func test_inMemoryFile_rangeReplaceableCollection() {
    let fhData1 = InMemoryFile()
    XCTAssertEqual(fhData1.count, 0)
    
    let fhData2 = InMemoryFile(repeating:0xFF, count:100)
    XCTAssertEqual(fhData2.count, 100)
    XCTAssertEqual(fhData2.randomElement(), 0xFF)
  }
  
  func test_inMemoryFile_mutableDataProtocol() {
    let fhData = InMemoryFile([0xFF, 0xFF, 0xFF, 0xFF])
    fhData.resetBytes(in: 1...2)
    XCTAssertEqual(fhData.availableData, Data([0xFF, 0x00, 0x00, 0xFF]))
  }
}

