/*
 * Copyright (c) 2014-2017 Tombo Inc. All Rights Reserved.
 *
 * This source code is a modified version of the objc4 sources released by Apple Inc. under
 * the terms of the APSL version 2.0 (see below).
 *
 */

// TEST_CONFIG

#include "test.h"
#include <objc/objc-runtime.h>
#define __APPLE_API_PRIVATE
#include <objc/objc-gdb.h>
#undef __APPLE_API_PRIVATE
#import <Foundation/NSObject.h>

@interface Foo:NSObject
@end
@implementation Foo
@end

int main()
{
#if __OBJC2__
    testassert(gdb_class_getClass([Foo class]) == [Foo class]);
#endif

    succeed(__FILE__);
}
