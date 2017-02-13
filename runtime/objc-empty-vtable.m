/*
 * Copyright (c) 2014-2017 Tombo Inc. All Rights Reserved.
 *
 * This source code is a modified version of the objc4 sources released by Apple Inc. under
 * the terms of the APSL version 2.0 (see below).
 *
 */

/*
Hack to define global symbol
from objc-cache.mm

asm("\n .section __TEXT,__const"
    "\n .globl __objc_empty_cache"
#if __LP64__
    "\n .align 3"
    "\n __objc_empty_cache: .quad 0"
#else
    "\n .align 2"
    "\n __objc_empty_cache: .long 0"
#endif
    "\n .globl __objc_empty_vtable"
    "\n .set __objc_empty_vtable, 0"
    );
*/
int _objc_empty_vtable = 0;
