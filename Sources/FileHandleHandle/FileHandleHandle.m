/***************************************************************************************************
 FileHandleHandle.m
   © 2019 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

#ifdef __MACH__

#import "FileHandleHandle.h"

@implementation _FileHandleHandle

- (instancetype) initWithFileHandle: (NSFileHandle *) fileHandle {
  if (self = [super init]) {
    self.__fileHandle = fileHandle;
  }
  return self;
}

@end

#endif
