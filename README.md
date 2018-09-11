# What is `SwiftTemporaryFile`?

`SwiftTemporaryFile` provides functions related to temporary files.
It was originally written as a part of [SwiftCGIResponder](https://github.com/YOCKOW/SwiftCGIResponder).

# Requirements

- Swift 4.1, 4.2
- macOS or Linux

# Usage

```Swift
import Foundation
import TemporaryFile

let tmpFile = TemporaryFile()
tmpFile.write("Hello, World!".data(using:.utf8)!)
tmpFile.seek(toFileOffset:0)
print(String(data:tmpFile.availableData, encoding:.utf8)!) // Prints "Hello, World!"
tmpFile.copy(to:URL(fileURLWithPath:"/my/directory/hello.txt"))
```

# License

MIT License.  
See "LICENSE.txt" for more information.

