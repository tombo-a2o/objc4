/*
 * Copyright (c) 2014-2017 Tombo Inc. All Rights Reserved.
 *
 * This source code is a modified version of the objc4 sources released by Apple Inc. under
 * the terms of the APSL version 2.0 (see below).
 *
 */

// TEST_CONFIG MEM=mrc,gc SDK=macosx,iphoneos

#include "test.h"
#include <objc/NSObject.h>

@interface Test : NSObject {
    char bytes[16-sizeof(void*)];
}
@end
@implementation Test
@end


int main()
{
    id o1 = [Test new];
    id o2 = object_copy(o1, 16);
    testassert(malloc_size(o1) == 16);
    testassert(malloc_size(o2) == 32);
    succeed(__FILE__);
}
