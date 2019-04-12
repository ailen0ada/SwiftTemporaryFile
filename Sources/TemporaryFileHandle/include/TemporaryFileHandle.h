/***************************************************************************************************
 TemporaryFileHandle.h
   © 2019 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

#ifdef __MACH__

#import <Foundation/Foundation.h>

@interface __TemporaryFileHandle : NSFileHandle

@property id __temporaryFile;
- (instancetype) initWithTemporaryFile: (id) temporaryFile;

@end

#endif
