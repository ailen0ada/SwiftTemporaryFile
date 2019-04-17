/***************************************************************************************************
 FileHandleHandle.h
   © 2019 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

#ifdef __MACH__

#import <Foundation/Foundation.h>

/// Pseudoclass to make `TemporaryFile` become a subclass of `FileHandle`.
/// Don't use this class directly.
@interface _FileHandleHandle : NSFileHandle

@property (nonatomic) NSFileHandle *__fileHandle;
- (instancetype) initWithFileHandle: (NSFileHandle *) fileHandle;

@end

#endif
