#if !canImport(ObjectiveC)
import XCTest

extension TemporaryFileTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__TemporaryFileTests = [
        ("test_fileHandleCompatibleData", test_fileHandleCompatibleData),
        ("test_fileHandleCompatibleData_collection", test_fileHandleCompatibleData_collection),
        ("test_fileHandleCompatibleData_mutableCollection", test_fileHandleCompatibleData_mutableCollection),
        ("test_fileHandleCompatibleData_mutableDataProtocol", test_fileHandleCompatibleData_mutableDataProtocol),
        ("test_fileHandleCompatibleData_rangeReplaceableCollection", test_fileHandleCompatibleData_rangeReplaceableCollection),
        ("test_fileHandleCompatibleData_sequence", test_fileHandleCompatibleData_sequence),
        ("test_temporaryDirectory", test_temporaryDirectory),
        ("test_temporaryFile", test_temporaryFile),
        ("test_temporaryFile_closure", test_temporaryFile_closure),
        ("test_temporaryFile_copy", test_temporaryFile_copy),
        ("test_temporaryFile_truncate", test_temporaryFile_truncate),
    ]
}

public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(TemporaryFileTests.__allTests__TemporaryFileTests),
    ]
}
#endif
