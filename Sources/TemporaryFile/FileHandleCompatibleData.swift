/* *************************************************************************************************
 FileHandleCompatibleData.swift
   © 2019 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation
import yExtensions

private func _unavailable(_ function:StaticString = #function) -> Never {
  fatalError("\(function) is unavailable in FileHandleCompatibleData.")
}

/// A byte buffer in memory that is (limitedly) compatible with `FileHandle`.
/// You can use this class instead of `TemporaryFile` for a specific purpose.
open class FileHandleCompatibleData: FileHandle_ {
  private var _data: Data!
  private var _offset: Int = 0
  private var _isClosed: Bool = false
  
  private init(data: Data) {
    #if canImport(ObjectiveC)
    super.init()
    #else
    super.init(fileDescriptor:-1, closeOnDealloc: false)
    #endif
    self._data = data
  }
  
  public convenience override init() {
    self.init(data: Data())
  }
  
  required public init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  open override func isEqual(_ object: Any?) -> Bool {
    guard case let anotherData as FileHandleCompatibleData = object else { return false }
    return self._data == anotherData._data
  }
  
  open override var hash: Int {
    return self._data.hashValue
  }
  
  open override var availableData: Data {
    return self.readData(ofLength: self._data.count - self._offset)
  }
  
  open override func closeFile() {
    self._isClosed = true
  }
  
  @available(*, unavailable, message: "You can't get the file descriptor of FileHandleCompatibleData.")
  open override var fileDescriptor: Int32 { _unavailable() }
  
  override open var offsetInFile: UInt64 {
    get {
      return UInt64(self._offset)
    }
    set {
      self._offset = Int(newValue)
    }
  }
  
  open override var readabilityHandler: ((FileHandle) -> Void)? {
    get {
      _unavailable()
    }
    set {
      _unavailable()
    }
  }
  
  open override func readData(ofLength length: Int) -> Data {
    if self._isClosed { return .init([]) }
    
    var end = self._offset + length
    if end > self._data.count { end = self._data.count }
    defer { self._offset = end - self._data.startIndex}
    
    return self._data[Data.RelativeIndex(self._offset)..<Data.RelativeIndex(end)]
  }
  
  open override func readDataToEndOfFile() -> Data {
    return self.availableData
  }
  
  open override func seek(toFileOffset offset: UInt64) {
    self.offsetInFile = offset
  }
  
  open override func seekToEndOfFile() -> UInt64 {
    let endOffset = UInt64(self._data.count)
    self.seek(toFileOffset: endOffset)
    return endOffset
  }
  
  open override func synchronizeFile() {
    _unavailable()
  }
  
  open override func truncateFile(atOffset offset: UInt64) {
    if offset > UInt64(self._data.count) {
      self._data += Data(count: Int(offset) - self._data.count)
    } else {
      self._data = self._data[Data.RelativeIndex(0)..<Data.RelativeIndex(Int(offset))]
    }
    self.offsetInFile = offset
  }
  
  open override var writeabilityHandler: ((FileHandle) -> Void)? {
    get {
      _unavailable()
    }
    set {
      _unavailable()
    }
  }
  
  open override func write(_ data: Data) {
    for byte: UInt8 in data {
      if self._offset < self._data.count {
        self._data[Data.RelativeIndex(self._offset)] = byte
      } else {
        self._data.append(byte)
      }
      self._offset += 1
    }
  }
}

extension FileHandleCompatibleData {
  /// Creates an empty buffer of a specified size.
  public convenience init(capacity: Int) {
    self.init(data: Data(capacity: capacity))
  }
  
  /// Creates a new buffer with the specified count of zeroed bytes.
  public convenience init(count: Int) {
    self.init(data: Data(count: count))
  }
  
  public convenience init<S>(_ elements: S) where S: Sequence, S.Element == UInt8 {
    self.init(data: Data(elements))
  }
  
  open var isEmpty: Bool {
    return self._data.isEmpty
  }
  
  open var count: Int {
    return self._data.count
  }
  
  /// Copies the contents of the data to memory.
  open func copyBytes(to pointer: UnsafeMutablePointer<UInt8>, count: Int) {
    self._data.copyBytes(to: pointer, count: count)
  }
}

extension FileHandleCompatibleData: Sequence, IteratorProtocol {
  public typealias Element = Data.Element
  public typealias Iterator = FileHandleCompatibleData
  
  public func next() -> Data.Element? {
    guard self._offset < self._data.count else { return nil }
    defer { self._offset += 1 }
    return self._data[Data.RelativeIndex(self._offset)]
  }
}
