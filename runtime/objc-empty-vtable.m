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
