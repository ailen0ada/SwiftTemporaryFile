/***************************************************************************************************
 TemporaryFileHandle.m
   © 2019 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

#ifdef __MACH__

#include "TemporaryFileHandle.h"

@implementation __TemporaryFileHandle

- (instancetype) initWithTemporaryFile: (id) temporaryFile {
  if (self = [super init]) {
    self.__temporaryFile = temporaryFile;
  }
  return self;
}

@end

#endif
