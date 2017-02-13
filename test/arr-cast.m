/*
 * Copyright (c) 2014-2017 Tombo Inc. All Rights Reserved.
 *
 * This source code is a modified version of the objc4 sources released by Apple Inc. under
 * the terms of the APSL version 2.0 (see below).
 *
 */

// TEST_CONFIG SDK=macosx,iphoneos

#include "test.h"

// objc.h redefines these calls into bridge casts.
// This test verifies that the function implementations are exported.
__BEGIN_DECLS
extern void *retainedObject(void *arg) __asm__("_objc_retainedObject");
extern void *unretainedObject(void *arg) __asm__("_objc_unretainedObject");
extern void *unretainedPointer(void *arg) __asm__("_objc_unretainedPointer");
__END_DECLS

int main()
{
    void *p = (void*)&main;
    testassert(p == retainedObject(p));
    testassert(p == unretainedObject(p));
    testassert(p == unretainedPointer(p));
    succeed(__FILE__);
}
