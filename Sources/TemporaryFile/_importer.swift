/* *************************************************************************************************
 _importer.swift
   © 2019 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
import Foundation

#if canImport(ObjectiveC)
import FileHandle__
/// Intermediate class that is subclass of `FileHandle`
public typealias FileHandle_ = FileHandle__
#else
public typealias FileHandle_ = FileHandle
#endif
