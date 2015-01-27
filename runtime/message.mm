#include "objc-private.h"
#include "objc.h"

extern "C" {

/*
typedef struct bucket_t *pbucket;

id objc_msgSend(id self, SEL sel, ...)
{
	// r0: self, r1: sel
	if(!self) return NULL;

	// ldr r9, [r0, #CLASS]
	Class cls = self->isa; // r9: cls

	cache_t cache = cls->cache; // [r9]

	// ldrh r12, [r9, #CACHE_MASK]
	mask_t mask = cache._mask; // r12
	// ldr r9, [r9, #CACHE]
	pbucket bucket_first = cache._buckets; // r9

	// and r12, r12, r1
	uintptr_t index = ((uintptr_t)sel) & ((uintptr_t)mask); // r12

	// add r9, r9, r12, LSL #3
	pbucket bucket = bucket_first + index * 8; // r9
	// TODO: pointer size

	// ldr r12, [r9]
	uintptr_t key = bucket->key(); // r12

//	va_list ap;
//	va_start(ap, sel);
//	void *arg1 = var_arg(ap, void*);


label2:
	// :2
	// teq r12, r1
	// bne 1f
	if((uintptr_t)sel == key) {
		// cache hit
		IMP imp = bucket->imp();
		return NULL; //imp(self, sel, ...);
	}

label1:
	// :1
	// cmp r12, #1
	if(key < 1) {
		// blo LCacheMiss
		IMP imp = _class_lookupMethodAndLoadCache3(self, sel, cls);
		return NULL; //imp(self, sel, ...);
	} else {
		// it eq
		// ldr r9, [r9, #4]
		bucket = (pbucket)((void*)bucket->imp()); // r9
	}
	key = (bucket+1)->key();
	goto label2;
}
*/
}
