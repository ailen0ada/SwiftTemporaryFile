/***************************************************************************************************
 FileHandle_.h
   © 2019 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

#ifdef __MACH__

#import <Foundation/Foundation.h>

/// Pseudoclass to make `TemporaryFile` become a subclass of `FileHandle`.
/// Don't use this class directly.
@interface FileHandle__ : NSFileHandle
- (instancetype) init;
@end

#endif
