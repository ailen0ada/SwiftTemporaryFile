/* *************************************************************************************************
 Process+TemporaryFile.swift
   © 2020 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
import Foundation

/// A type that has an IO of `Process`.
/// It is expected that conforming types for `ProcessIO`(`associatedtype`) are
/// *only* `FileHandle`, `Pipe`, and `TemporaryFile`.
public protocol ProcessIOConvertible {
  associatedtype ProcessIO: ProcessIOConvertible
  var processIO: ProcessIO { get }
}

extension ProcessIOConvertible where Self.ProcessIO == Self {
  public var processIO: Self {
    return self
  }
}

extension FileHandle: ProcessIOConvertible {
  public typealias ProcessIO = FileHandle
}

extension Pipe: ProcessIOConvertible {
  public typealias ProcessIO = Pipe
}

extension TemporaryFile: ProcessIOConvertible {
  public typealias ProcessIO = TemporaryFile
}

private var _temporaryFileTable: [FileHandle:TemporaryFile] = [:]

extension Process {
  public enum IOType {
    case standardError
    case standardInput
    case standardOutput
    
    fileprivate var _keyPath: ReferenceWritableKeyPath<Process, Any?> {
      switch self {
      case .standardError: return \.standardError
      case .standardInput: return \.standardInput
      case .standardOutput: return \.standardOutput
      }
    }
  }
  
  /// Returns IO for the specified IO type.
  /// You must explicitly declare the type for getter with care.
  /// It is to be desired that only setter is used.
  public subscript<IO>(_ ioType: IOType) -> IO? where IO: ProcessIOConvertible {
    get {
      switch self[keyPath: ioType._keyPath] {
      case nil:
        return nil
      case let pipe as Pipe:
        return (pipe as! IO)
      case let fileHandle as FileHandle:
        if let temporaryFile = _temporaryFileTable[fileHandle] {
          return (temporaryFile as! IO)
        }
        return (fileHandle as! IO)
      default:
        fatalError("Unsupported IO.")
      }
    }
    set {
      let propertyPath = ioType._keyPath
      guard let someIO = newValue?.processIO else { self[keyPath: propertyPath] = nil; return }
      switch someIO {
      case let pipe as Pipe:
        self[keyPath: propertyPath] = pipe
      case let fileHandle as FileHandle:
        self[keyPath: propertyPath] = fileHandle
      case let temporaryFile as TemporaryFile:
        let fh = temporaryFile.__fileHandle
        self[keyPath: propertyPath] = fh
        _temporaryFileTable[fh] = temporaryFile
      default:
        fatalError("Unsupported IO.")
      }
    }
  }
}
