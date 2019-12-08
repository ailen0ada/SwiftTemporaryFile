/* *************************************************************************************************
 InMemoryFile.swift
   © 2019 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation
import yExtensions

@available(*, deprecated, renamed: "InMemoryFile")
public typealias FileHandleCompatibleData = InMemoryFile

private func _unavailable(_ function:StaticString = #function) -> Never {
  fatalError("\(function) is unavailable in InMemoryFile.")
}

/// A byte buffer in memory that is (limitedly) compatible with `FileHandle`.
/// You can use this class instead of `TemporaryFile` for a specific purpose.
open class InMemoryFile: FileHandle_ {
  private var _data: Data
  private var _offset: Int = 0
  private var _isClosed: Bool = false
  
  private init(_data data: Data) {
    self._data = data
    #if canImport(ObjectiveC)
    super.init()
    #else
    super.init(fileDescriptor:-1, closeOnDealloc: false)
    #endif
  }
  
  #if canImport(ObjectiveC)
  public convenience required override init() {
    self.init(_data: Data())
  }
  #else
  public convenience required init() {
    self.init(_data: Data())
  }
  #endif
  
  public convenience required init<S>(_ elements: S) where S: Sequence, S.Element == UInt8 {
    self.init(_data: Data(elements))
  }
  
  required public init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  open override func isEqual(_ object: Any?) -> Bool {
    guard case let anotherData as InMemoryFile = object else { return false }
    return self._data == anotherData._data
  }
  
  open override var hash: Int {
    return self._data.hashValue
  }
  
  open override var availableData: Data {
    return self.readData(ofLength: self._data.count - self._offset)
  }
  
  open override func close() throws {
    self._isClosed = true
  }
  
  @available(*, deprecated, renamed: "close", message: "Use `func close() throws` instead.")
  open override func closeFile() {
    try! self.close()
  }
  
  @available(*, unavailable, message: "You can't get the file descriptor of FileHandleCompatibleData.")
  open override var fileDescriptor: Int32 {
    return -1
  }
  
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
    if self._isClosed { return .init() }
    
    var end = self._offset + length
    if end > self._data.count { end = self._data.count }
    defer { self._offset = end - self._data.startIndex}
    
    return self._data[Data.RelativeIndex(self._offset)..<Data.RelativeIndex(end)]
  }
  
  open override func readDataToEndOfFile() -> Data {
    return self.availableData
  }
  
  @available(*, deprecated, renamed: "seek(toOffset:)", message: "Use `func seek(toOffset offset: UInt64) throws` instead.")
  open override func seek(toFileOffset offset: UInt64) {
    try! self.seek(toOffset: offset)
  }
  
  public override func seek(toOffset offset: UInt64) throws {
    guard offset >= 0 && offset <= self._data.count else { throw TemporaryFileError.outOfRange }
    self.offsetInFile = offset
  }
  
  open override func seekToEndOfFile() -> UInt64 {
    let endOffset = UInt64(self._data.count)
    try! self.seek(toOffset: endOffset)
    return endOffset
  }
  
  open override func synchronize() throws {
    _unavailable()
  }
  
  open override func synchronizeFile() {
    try! self.synchronize()
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

extension InMemoryFile {
  /// Creates an empty buffer of a specified size.
  public convenience init(capacity: Int) {
    self.init(_data: Data(capacity: capacity))
  }
  
  /// Creates a new buffer with the specified count of zeroed bytes.
  public convenience init(count: Int) {
    self.init(_data: Data(count: count))
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

extension InMemoryFile: Sequence, IteratorProtocol {
  public typealias Element = Data.Element
  public typealias Iterator = InMemoryFile
  
  public func next() -> Data.Element? {
    guard self._offset < self._data.count else { return nil }
    defer { self._offset += 1 }
    return self._data[Data.RelativeIndex(self._offset)]
  }
}

extension InMemoryFile: Collection {
  public typealias Index = Int
  
  public subscript(position: Int) -> Data.Element {
    get {
      return self._data[Data.RelativeIndex(position)]
    }
    set {
      self._data[Data.RelativeIndex(position)] = newValue
    }
  }
  
  public var startIndex: Int { return 0 }
  
  public var endIndex: Int { return self._data.count }
  
  public func index(after ii: Int) -> Int {
    return ii + 1
  }
}

extension InMemoryFile: BidirectionalCollection {
  public func index(before ii: Int) -> Int {
    return ii - 1
  }
}

extension InMemoryFile: RandomAccessCollection {}

extension InMemoryFile: MutableCollection, RangeReplaceableCollection {
  public func append<S>(contentsOf newElements: S) where S: Sequence, S.Element == Data.Element {
    self._data.append(contentsOf:newElements)
  }
  
  public func reserveCapacity(_ nn: Int) {
    self._data.reserveCapacity(nn)
  }
}

extension InMemoryFile: ContiguousBytes {
  public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
    return try self._data.withUnsafeBytes(body)
  }
}

extension InMemoryFile: DataProtocol {
  public typealias Regions = CollectionOfOne<InMemoryFile>
  
  public var regions: CollectionOfOne<InMemoryFile> {
    return CollectionOfOne(self)
  }
}

extension InMemoryFile: MutableDataProtocol {
  public func resetBytes<R: RangeExpression>(in range: R) where R.Bound == Index {
    self._data.resetBytes(in: range)
  }
}
