/*
 * Copyright (c) 1999-2007 Apple Inc.  All Rights Reserved.
 *
 * @APPLE_LICENSE_HEADER_START@
 *
 * This file contains Original Code and/or Modifications of Original Code
 * as defined in and that are subject to the Apple Public Source License
 * Version 2.0 (the 'License'). You may not use this file except in
 * compliance with the License. Please obtain a copy of the License at
 * http://www.opensource.apple.com/apsl/ and read it before using this
 * file.
 *
 * The Original Code and all software distributed under the License are
 * distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR NON-INFRINGEMENT.
 * Please see the License for the specific language governing rights and
 * limitations under the License.
 *
 * @APPLE_LICENSE_HEADER_END@
 */
/*
 *	objc-private.h
 *	Copyright 1988-1996, NeXT Software, Inc.
 */

#ifndef _OBJC_PRIVATE_H_
#define _OBJC_PRIVATE_H_

#include "objc-config.h"

/* Isolate ourselves from the definitions of id and Class in the compiler
 * and public headers.
 */

#ifdef _OBJC_OBJC_H_
#error include objc-private.h before other headers
#endif

#define OBJC_TYPES_DEFINED 1
#define OBJC_OLD_DISPATCH_PROTOTYPES 0

#include <cstddef>  // for nullptr_t
#include <stdint.h>
#include <assert.h>

struct objc_class;
struct objc_object;

typedef struct objc_class *Class;
typedef struct objc_object *id;

namespace {
    class SideTable;
};


union isa_t
{
    isa_t() { }
    isa_t(uintptr_t value) : bits(value) { }

    Class cls;
    uintptr_t bits;

#if SUPPORT_NONPOINTER_ISA

    // extra_rc must be the MSB-most field (so it matches carry/overflow flags)
    // indexed must be the LSB (fixme or get rid of it)
    // shiftcls must occupy the same bits that a real class pointer would
    // bits + RC_ONE is equivalent to extra_rc + 1
    // RC_HALF is the high bit of extra_rc (i.e. half of its range)

    // future expansion:
    // uintptr_t fast_rr : 1;     // no r/r overrides
    // uintptr_t lock : 2;        // lock for atomic property, @synch
    // uintptr_t extraBytes : 1;  // allocated with extra bytes

# if __arm64__
#   define ISA_MASK        0x00000001fffffff8ULL
#   define ISA_MAGIC_MASK  0x000003fe00000001ULL
#   define ISA_MAGIC_VALUE 0x000001a400000001ULL
    struct {
        uintptr_t indexed           : 1;
        uintptr_t has_assoc         : 1;
        uintptr_t has_cxx_dtor      : 1;
        uintptr_t shiftcls          : 30; // MACH_VM_MAX_ADDRESS 0x1a0000000
        uintptr_t magic             : 9;
        uintptr_t weakly_referenced : 1;
        uintptr_t deallocating      : 1;
        uintptr_t has_sidetable_rc  : 1;
        uintptr_t extra_rc          : 19;
#       define RC_ONE   (1ULL<<45)
#       define RC_HALF  (1ULL<<18)
    };

# elif __x86_64__
#   define ISA_MASK        0x00007ffffffffff8ULL
#   define ISA_MAGIC_MASK  0x0000000000000001ULL
#   define ISA_MAGIC_VALUE 0x0000000000000001ULL
    struct {
        uintptr_t indexed           : 1;
        uintptr_t has_assoc         : 1;
        uintptr_t has_cxx_dtor      : 1;
        uintptr_t shiftcls          : 44; // MACH_VM_MAX_ADDRESS 0x7fffffe00000
        uintptr_t weakly_referenced : 1;
        uintptr_t deallocating      : 1;
        uintptr_t has_sidetable_rc  : 1;
        uintptr_t extra_rc          : 14;
#       define RC_ONE   (1ULL<<50)
#       define RC_HALF  (1ULL<<13)
    };

# else
    // Available bits in isa field are architecture-specific.
#   error unknown architecture
# endif

// SUPPORT_NONPOINTER_ISA
#endif

};


struct objc_object {
private:
    isa_t isa;

public:

    // ISA() assumes this is NOT a tagged pointer object
    Class ISA();

    // getIsa() allows this to be a tagged pointer object
    Class getIsa();

    // initIsa() should be used to init the isa of new objects only.
    // If this object already has an isa, use changeIsa() for correctness.
    // initInstanceIsa(): objects with no custom RR/AWZ
    // initClassIsa(): class objects
    // initProtocolIsa(): protocol objects
    // initIsa(): other objects
    void initIsa(Class cls /*indexed=false*/);
    void initClassIsa(Class cls /*indexed=maybe*/);
    void initProtocolIsa(Class cls /*indexed=maybe*/);
    void initInstanceIsa(Class cls, bool hasCxxDtor);

    // changeIsa() should be used to change the isa of existing objects.
    // If this is a new object, use initIsa() for performance.
    Class changeIsa(Class newCls);

    bool hasIndexedIsa();
    bool isTaggedPointer();
    bool isClass();

    // object may have associated objects?
    bool hasAssociatedObjects();
    void setHasAssociatedObjects();

    // object may be weakly referenced?
    bool isWeaklyReferenced();
    void setWeaklyReferenced_nolock();

    // object may have -.cxx_destruct implementation?
    bool hasCxxDtor();

    // Optimized calls to retain/release methods
    id retain();
    void release();
    id autorelease();

    // Implementations of retain/release methods
    id rootRetain();
    bool rootRelease();
    id rootAutorelease();
    bool rootTryRetain();
    bool rootReleaseShouldDealloc();
    uintptr_t rootRetainCount();

    // Implementation of dealloc methods
    bool rootIsDeallocating();
    void clearDeallocating();
    void rootDealloc();

private:
    void initIsa(Class newCls, bool indexed, bool hasCxxDtor);

    // Slow paths for inline control
    id rootAutorelease2();
    bool overrelease_error();

#if SUPPORT_NONPOINTER_ISA
    // Unified retain count manipulation for nonpointer isa
    id rootRetain(bool tryRetain, bool handleOverflow);
    bool rootRelease(bool performDealloc, bool handleUnderflow);
    id rootRetain_overflow(bool tryRetain);
    bool rootRelease_underflow(bool performDealloc);

    void clearDeallocating_weak();

    // Side table retain count overflow for nonpointer isa
    void sidetable_lock();
    void sidetable_unlock();

    void sidetable_moveExtraRC_nolock(size_t extra_rc, bool isDeallocating, bool weaklyReferenced);
    bool sidetable_addExtraRC_nolock(size_t delta_rc);
    bool sidetable_subExtraRC_nolock(size_t delta_rc);
    size_t sidetable_getExtraRC_nolock();
#endif

    // Side-table-only retain count
    bool sidetable_isDeallocating();
    void sidetable_clearDeallocating();

    bool sidetable_isWeaklyReferenced();
    void sidetable_setWeaklyReferenced_nolock();

    id sidetable_retain();
    id sidetable_retain_slow(SideTable *table);

    bool sidetable_release(bool performDealloc = true);
    bool sidetable_release_slow(SideTable *table, bool performDealloc = true);

    bool sidetable_tryRetain();

    uintptr_t sidetable_retainCount();
#if !NDEBUG
    bool sidetable_present();
#endif
};


#if __OBJC2__
typedef struct method_t *Method;
typedef struct ivar_t *Ivar;
typedef struct category_t *Category;
typedef struct property_t *objc_property_t;
#else
typedef struct old_method *Method;
typedef struct old_ivar *Ivar;
typedef struct old_category *Category;
typedef struct old_property *objc_property_t;
#endif

// Public headers

#include "objc.h"
#include "runtime.h"
#include "objc-os.h"
#include "objc-abi.h"
#include "objc-api.h"
#include "objc-auto.h"
#include "objc-config.h"
#include "objc-internal.h"
#include "maptable.h"
#include "hashtable2.h"

/* Do not include message.h here. */
/* #include "message.h" */

#define __APPLE_API_PRIVATE
#include "objc-gdb.h"
#undef __APPLE_API_PRIVATE


// Private headers

#if __OBJC2__
#include "objc-runtime-new.h"
#else
#include "objc-runtime-old.h"
#endif

#include "objc-references.h"
#include "objc-initialize.h"
#include "objc-loadmethod.h"


__BEGIN_DECLS


#if (defined(OBJC_NO_GC) && SUPPORT_GC)  ||  \
    (!defined(OBJC_NO_GC) && !SUPPORT_GC)
#   error OBJC_NO_GC and SUPPORT_GC inconsistent
#endif

#if SUPPORT_GC
#   include <auto_zone.h>
    // PRIVATE_EXTERN is needed to help the compiler know "how" extern these are
    PRIVATE_EXTERN extern int8_t UseGC;          // equivalent to calling objc_collecting_enabled()
    PRIVATE_EXTERN extern auto_zone_t *gc_zone;  // the GC zone, or NULL if no GC
    extern void objc_addRegisteredClass(Class c);
    extern void objc_removeRegisteredClass(Class c);
#else
#   define UseGC NO
#   define gc_zone NULL
#   define objc_addRegisteredClass(c) do {} while(0)
#   define objc_removeRegisteredClass(c) do {} while(0)
    /* Uses of the following must be protected with UseGC. */
    extern id gc_unsupported_dont_call();
#   define auto_zone_allocate_object gc_unsupported_dont_call
#   define auto_zone_retain gc_unsupported_dont_call
#   define auto_zone_release gc_unsupported_dont_call
#   define auto_zone_is_valid_pointer gc_unsupported_dont_call
#   define auto_zone_write_barrier_memmove gc_unsupported_dont_call
#   define AUTO_OBJECT_SCANNED 0
#endif


#define _objcHeaderIsReplacement(h)  ((h)->info  &&  ((h)->info->flags & OBJC_IMAGE_IS_REPLACEMENT))

/* OBJC_IMAGE_IS_REPLACEMENT:
   Don't load any classes
   Don't load any categories
   Do fix up selector refs (@selector points to them)
   Do fix up class refs (@class and objc_msgSend points to them)
   Do fix up protocols (@protocol points to them)
   Do fix up superclass pointers in classes ([super ...] points to them)
   Future: do load new classes?
   Future: do load new categories?
   Future: do insert new methods on existing classes?
   Future: do insert new methods on existing categories?
*/

#define _objcInfoSupportsGC(info) (((info)->flags & OBJC_IMAGE_SUPPORTS_GC) ? 1 : 0)
#define _objcInfoRequiresGC(info) (((info)->flags & OBJC_IMAGE_REQUIRES_GC) ? 1 : 0)
#define _objcHeaderSupportsGC(h) ((h)->info && _objcInfoSupportsGC((h)->info))
#define _objcHeaderRequiresGC(h) ((h)->info && _objcInfoRequiresGC((h)->info))

/* OBJC_IMAGE_SUPPORTS_GC:
    was compiled with -fobjc-gc flag, regardless of whether write-barriers were issued
    if executable image compiled this way, then all subsequent libraries etc. must also be this way
*/

#define _objcHeaderOptimizedByDyld(h)  ((h)->info  &&  ((h)->info->flags & OBJC_IMAGE_OPTIMIZED_BY_DYLD))

/* OBJC_IMAGE_OPTIMIZED_BY_DYLD:
   Assorted metadata precooked in the dyld shared cache.
   Never set for images outside the shared cache file itself.
*/


typedef struct _header_info {
    struct _header_info *next;
    const headerType *mhdr;
    const objc_image_info *info;
    const char *fname;  // same as Dl_info.dli_fname
    bool loaded;
    bool inSharedCache;
    bool allClassesRealized;

    // Do not add fields without editing ObjCModernAbstraction.hpp

#if !__OBJC2__
    struct old_protocol **proto_refs;
    struct objc_module *mod_ptr;
    size_t              mod_count;
# if TARGET_OS_WIN32
    struct objc_module **modules;
    size_t moduleCount;
    struct old_protocol **protocols;
    size_t protocolCount;
    void *imageinfo;
    size_t imageinfoBytes;
    SEL *selrefs;
    size_t selrefCount;
    struct objc_class **clsrefs;
    size_t clsrefCount;
    TCHAR *moduleName;
# endif
#endif
} header_info;

extern header_info *FirstHeader;
extern header_info *LastHeader;
extern int HeaderCount;

extern uint32_t AppSDKVersion;  // X.Y.Z is 0xXXXXYYZZ

extern void appendHeader(header_info *hi);
extern void removeHeader(header_info *hi);

extern objc_image_info *_getObjcImageInfo(const headerType *head, size_t *size);
extern BOOL _hasObjcContents(const header_info *hi);


/* selectors */
extern void sel_init(BOOL gc, size_t selrefCount);
extern SEL sel_registerNameNoLock(const char *str, BOOL copy);
extern void sel_lock(void);
extern void sel_unlock(void);
extern BOOL sel_preoptimizationValid(const header_info *hi);

extern SEL SEL_load;
extern SEL SEL_initialize;
extern SEL SEL_resolveClassMethod;
extern SEL SEL_resolveInstanceMethod;
extern SEL SEL_cxx_construct;
extern SEL SEL_cxx_destruct;
extern SEL SEL_retain;
extern SEL SEL_release;
extern SEL SEL_autorelease;
extern SEL SEL_retainCount;
extern SEL SEL_alloc;
extern SEL SEL_allocWithZone;
extern SEL SEL_dealloc;
extern SEL SEL_copy;
extern SEL SEL_new;
extern SEL SEL_finalize;
extern SEL SEL_forwardInvocation;
extern SEL SEL_tryRetain;
extern SEL SEL_isDeallocating;
extern SEL SEL_retainWeakReference;
extern SEL SEL_allowsWeakReference;

/* preoptimization */
extern void preopt_init(void);
extern void disableSharedCacheOptimizations(void);
extern bool isPreoptimized(void);
extern header_info *preoptimizedHinfoForHeader(const headerType *mhdr);

#if SUPPORT_PREOPT  &&  __cplusplus
#include <objc-shared-cache.h>
using objc_selopt_t = const objc_opt::objc_selopt_t;
#else
struct objc_selopt_t;
#endif

extern objc_selopt_t *preoptimizedSelectors(void);
extern Class getPreoptimizedClass(const char *name);
extern Class* copyPreoptimizedClasses(const char *name, int *outCount);


/* optional malloc zone for runtime data */
extern malloc_zone_t *_objc_internal_zone(void);
extern void *_malloc_internal(size_t size);
extern void *_calloc_internal(size_t count, size_t size);
extern void *_realloc_internal(void *ptr, size_t size);
extern char *_strdup_internal(const char *str);
extern char *_strdupcat_internal(const char *s1, const char *s2);
extern uint8_t *_ustrdup_internal(const uint8_t *str);
extern void *_memdup_internal(const void *mem, size_t size);
extern void _free_internal(void *ptr);
extern size_t _malloc_size_internal(void *ptr);

extern Class _calloc_class(size_t size);

/* method lookup */
extern IMP lookUpImpOrNil(Class, SEL, id obj, bool initialize, bool cache, bool resolver);
extern IMP lookUpImpOrForward(Class, SEL, id obj, bool initialize, bool cache, bool resolver);

extern IMP lookupMethodInClassAndLoadCache(Class cls, SEL sel);
extern BOOL class_respondsToSelector_inst(Class cls, SEL sel, id inst);

extern bool objcMsgLogEnabled;
extern bool logMessageSend(bool isClassMethod,
                    const char *objectsClass,
                    const char *implementingClass,
                    SEL selector);

/* message dispatcher */
extern IMP _class_lookupMethodAndLoadCache3(id, SEL, Class);

#if !OBJC_OLD_DISPATCH_PROTOTYPES
#define _objc_msgForward_impcache ((IMP)2)
//extern void _objc_msgForward_impcache(void);
extern void _objc_ignored_method(void);
extern void _objc_msgSend_uncached_impcache(void);
#else
extern id _objc_msgForward_impcache(id, SEL, ...);
extern id _objc_ignored_method(id, SEL, ...);
extern id _objc_msgSend_uncached_impcache(id, SEL, ...);
#endif

/* errors */
extern void __objc_error(id, const char *, ...) __attribute__((format (printf, 2, 3), noreturn));
extern void _objc_inform(const char *fmt, ...) __attribute__((format (printf, 1, 2)));
extern void _objc_inform_on_crash(const char *fmt, ...) __attribute__((format (printf, 1, 2)));
extern void _objc_inform_now_and_on_crash(const char *fmt, ...) __attribute__((format (printf, 1, 2)));
extern void _objc_inform_deprecated(const char *oldname, const char *newname) __attribute__((noinline));
extern void inform_duplicate(const char *name, Class oldCls, Class cls);
extern bool crashlog_header_name(header_info *hi);
extern bool crashlog_header_name_string(const char *name);

/* magic */
extern Class _objc_getFreedObjectClass (void);

/* map table additions */
extern void *NXMapKeyCopyingInsert(NXMapTable *table, const void *key, const void *value);
extern void *NXMapKeyFreeingRemove(NXMapTable *table, const void *key);

/* hash table additions */
extern unsigned _NXHashCapacity(NXHashTable *table);
extern void _NXHashRehashToCapacity(NXHashTable *table, unsigned newCapacity);

/* property attribute parsing */
extern const char *copyPropertyAttributeString(const objc_property_attribute_t *attrs, unsigned int count);
extern objc_property_attribute_t *copyPropertyAttributeList(const char *attrs, unsigned int *outCount);
extern char *copyPropertyAttributeValue(const char *attrs, const char *name);

/* locking */
extern void lock_init(void);
extern rwlock_t selLock;
extern mutex_t cacheUpdateLock;
extern recursive_mutex_t loadMethodLock;
#if __OBJC2__
extern rwlock_t runtimeLock;
#else
extern mutex_t classLock;
extern mutex_t methodListLock;
#endif

/* Lock debugging */
#if defined(NDEBUG)  ||  TARGET_OS_WIN32 || 1

#define mutex_lock(m)             _mutex_lock_nodebug(m)
#define mutex_try_lock(m)         _mutex_try_lock_nodebug(m)
#define mutex_unlock(m)           _mutex_unlock_nodebug(m)
#define mutex_assert_locked(m)    do { } while (0)
#define mutex_assert_unlocked(m)  do { } while (0)

#define recursive_mutex_lock(m)             _recursive_mutex_lock_nodebug(m)
#define recursive_mutex_try_lock(m)         _recursive_mutex_try_lock_nodebug(m)
#define recursive_mutex_unlock(m)           _recursive_mutex_unlock_nodebug(m)
#define recursive_mutex_assert_locked(m)    do { } while (0)
#define recursive_mutex_assert_unlocked(m)  do { } while (0)

#define monitor_enter(m)            _monitor_enter_nodebug(m)
#define monitor_exit(m)             _monitor_exit_nodebug(m)
#define monitor_wait(m)             _monitor_wait_nodebug(m)
#define monitor_assert_locked(m)    do { } while (0)
#define monitor_assert_unlocked(m)  do { } while (0)

#define rwlock_read(m)              _rwlock_read_nodebug(m)
#define rwlock_write(m)             _rwlock_write_nodebug(m)
#define rwlock_try_read(m)          _rwlock_try_read_nodebug(m)
#define rwlock_try_write(m)         _rwlock_try_write_nodebug(m)
#define rwlock_unlock_read(m)       _rwlock_unlock_read_nodebug(m)
#define rwlock_unlock_write(m)      _rwlock_unlock_write_nodebug(m)
#define rwlock_assert_reading(m)    do { } while (0)
#define rwlock_assert_writing(m)    do { } while (0)
#define rwlock_assert_locked(m)     do { } while (0)
#define rwlock_assert_unlocked(m)   do { } while (0)

#else

extern int _mutex_lock_debug(mutex_t *lock, const char *name);
extern int _mutex_try_lock_debug(mutex_t *lock, const char *name);
extern int _mutex_unlock_debug(mutex_t *lock, const char *name);
extern void _mutex_assert_locked_debug(mutex_t *lock, const char *name);
extern void _mutex_assert_unlocked_debug(mutex_t *lock, const char *name);

extern int _recursive_mutex_lock_debug(recursive_mutex_t *lock, const char *name);
extern int _recursive_mutex_try_lock_debug(recursive_mutex_t *lock, const char *name);
extern int _recursive_mutex_unlock_debug(recursive_mutex_t *lock, const char *name);
extern void _recursive_mutex_assert_locked_debug(recursive_mutex_t *lock, const char *name);
extern void _recursive_mutex_assert_unlocked_debug(recursive_mutex_t *lock, const char *name);

extern int _monitor_enter_debug(monitor_t *lock, const char *name);
extern int _monitor_exit_debug(monitor_t *lock, const char *name);
extern int _monitor_wait_debug(monitor_t *lock, const char *name);
extern void _monitor_assert_locked_debug(monitor_t *lock, const char *name);
extern void _monitor_assert_unlocked_debug(monitor_t *lock, const char *name);

extern void _rwlock_read_debug(rwlock_t *l, const char *name);
extern void _rwlock_write_debug(rwlock_t *l, const char *name);
extern int  _rwlock_try_read_debug(rwlock_t *l, const char *name);
extern int  _rwlock_try_write_debug(rwlock_t *l, const char *name);
extern void _rwlock_unlock_read_debug(rwlock_t *l, const char *name);
extern void _rwlock_unlock_write_debug(rwlock_t *l, const char *name);
extern void _rwlock_assert_reading_debug(rwlock_t *l, const char *name);
extern void _rwlock_assert_writing_debug(rwlock_t *l, const char *name);
extern void _rwlock_assert_locked_debug(rwlock_t *l, const char *name);
extern void _rwlock_assert_unlocked_debug(rwlock_t *l, const char *name);

#define mutex_lock(m)             _mutex_lock_debug (m, #m)
#define mutex_try_lock(m)         _mutex_try_lock_debug (m, #m)
#define mutex_unlock(m)           _mutex_unlock_debug (m, #m)
#define mutex_assert_locked(m)    _mutex_assert_locked_debug (m, #m)
#define mutex_assert_unlocked(m)  _mutex_assert_unlocked_debug (m, #m)

#define recursive_mutex_lock(m)             _recursive_mutex_lock_debug (m, #m)
#define recursive_mutex_try_lock(m)         _recursive_mutex_try_lock_debug (m, #m)
#define recursive_mutex_unlock(m)           _recursive_mutex_unlock_debug (m, #m)
#define recursive_mutex_assert_locked(m)    _recursive_mutex_assert_locked_debug (m, #m)
#define recursive_mutex_assert_unlocked(m)  _recursive_mutex_assert_unlocked_debug (m, #m)

#define monitor_enter(m)            _monitor_enter_debug(m, #m)
#define monitor_exit(m)             _monitor_exit_debug(m, #m)
#define monitor_wait(m)             _monitor_wait_debug(m, #m)
#define monitor_assert_locked(m)    _monitor_assert_locked_debug(m, #m)
#define monitor_assert_unlocked(m)  _monitor_assert_unlocked_debug(m, #m)

#define rwlock_read(m)              _rwlock_read_debug(m, #m)
#define rwlock_write(m)             _rwlock_write_debug(m, #m)
#define rwlock_try_read(m)          _rwlock_try_read_debug(m, #m)
#define rwlock_try_write(m)         _rwlock_try_write_debug(m, #m)
#define rwlock_unlock_read(m)       _rwlock_unlock_read_debug(m, #m)
#define rwlock_unlock_write(m)      _rwlock_unlock_write_debug(m, #m)
#define rwlock_assert_reading(m)    _rwlock_assert_reading_debug(m, #m)
#define rwlock_assert_writing(m)    _rwlock_assert_writing_debug(m, #m)
#define rwlock_assert_locked(m)     _rwlock_assert_locked_debug(m, #m)
#define rwlock_assert_unlocked(m)   _rwlock_assert_unlocked_debug(m, #m)

#endif

#define rwlock_unlock(m, s)                           \
    do {                                              \
        if ((s) == RDONLY) rwlock_unlock_read(m);     \
        else if ((s) == RDWR) rwlock_unlock_write(m); \
    } while (0)


/* ignored selector support */

/* Non-GC: no ignored selectors
   GC (i386 Mac): some selectors ignored, remapped to kIgnore
   GC (others): some selectors ignored, but not remapped
*/

static inline int ignoreSelector(SEL sel)
{
#if !SUPPORT_GC
    return NO;
#elif SUPPORT_IGNORED_SELECTOR_CONSTANT
    return UseGC  &&  sel == (SEL)kIgnore;
#else
    return UseGC  &&
        (sel == @selector(retain)       ||
         sel == @selector(release)      ||
         sel == @selector(autorelease)  ||
         sel == @selector(retainCount)  ||
         sel == @selector(dealloc));
#endif
}

static inline int ignoreSelectorNamed(const char *sel)
{
#if !SUPPORT_GC
    return NO;
#else
    // release retain retainCount dealloc autorelease
    return (UseGC &&
            (  (sel[0] == 'r' && sel[1] == 'e' &&
                (strcmp(&sel[2], "lease") == 0 ||
                 strcmp(&sel[2], "tain") == 0 ||
                 strcmp(&sel[2], "tainCount") == 0 ))
               ||
               (strcmp(sel, "dealloc") == 0)
               ||
               (sel[0] == 'a' && sel[1] == 'u' &&
                strcmp(&sel[2], "torelease") == 0)));
#endif
}

/* GC startup */
extern void gc_init(BOOL wantsGC);
extern void gc_init2(void);

/* Exceptions */
struct alt_handler_list;
extern void exception_init(void);
extern void _destroyAltHandlerList(struct alt_handler_list *list);

/* Class change notifications (gdb only for now) */
#define OBJC_CLASS_ADDED (1<<0)
#define OBJC_CLASS_REMOVED (1<<1)
#define OBJC_CLASS_IVARS_CHANGED (1<<2)
#define OBJC_CLASS_METHODS_CHANGED (1<<3)
extern void gdb_objc_class_changed(Class cls, unsigned long changes, const char *classname)
    __attribute__((noinline));

#if SUPPORT_GC

/* Write barrier implementations */
extern id objc_getAssociatedObject_non_gc(id object, const void *key);
extern void objc_setAssociatedObject_non_gc(id object, const void *key, id value, objc_AssociationPolicy policy);

extern id objc_getAssociatedObject_gc(id object, const void *key);
extern void objc_setAssociatedObject_gc(id object, const void *key, id value, objc_AssociationPolicy policy);

/* xrefs */
extern objc_xref_t _object_addExternalReference_non_gc(id obj, objc_xref_t type);
extern id _object_readExternalReference_non_gc(objc_xref_t ref);
extern void _object_removeExternalReference_non_gc(objc_xref_t ref);

extern objc_xref_t _object_addExternalReference_gc(id obj, objc_xref_t type);
extern id _object_readExternalReference_gc(objc_xref_t ref);
extern void _object_removeExternalReference_gc(objc_xref_t ref);

/* GC weak reference fixup. */
extern void gc_fixup_weakreferences(id newObject, id oldObject);

/* GC datasegment registration. */
extern void gc_register_datasegment(uintptr_t base, size_t size);
extern void gc_unregister_datasegment(uintptr_t base, size_t size);

/* objc_dumpHeap implementation */
extern BOOL _objc_dumpHeap(auto_zone_t *zone, const char *filename);

#endif


// Settings from environment variables
#define OPTION(var, env, help) extern bool var;
#include "objc-env.h"
#undef OPTION

extern void environ_init(void);

extern void logReplacedMethod(const char *className, SEL s, BOOL isMeta, const char *catName, IMP oldImp, IMP newImp);

static __inline uint32_t _objc_strhash(const char *s) {
    uint32_t hash = 0;
    for (;;) {
	int a = *s++;
	if (0 == a) break;
	hash += (hash << 8) + a;
    }
    return hash;
}


// objc per-thread storage
typedef struct {
    struct _objc_initializing_classes *initializingClasses; // for +initialize
    struct SyncCache *syncCache;  // for @synchronize
    struct alt_handler_list *handlerList;  // for exception alt handlers
    char *printableNames[4];  // temporary demangled names for logging

    // If you add new fields here, don't forget to update
    // _objc_pthread_destroyspecific()

} _objc_pthread_data;

extern _objc_pthread_data *_objc_fetch_pthread_data(BOOL create);
extern void tls_init(void);

// encoding.h
extern unsigned int encoding_getNumberOfArguments(const char *typedesc);
extern unsigned int encoding_getSizeOfArguments(const char *typedesc);
extern unsigned int encoding_getArgumentInfo(const char *typedesc, unsigned int arg, const char **type, int *offset);
extern void encoding_getReturnType(const char *t, char *dst, size_t dst_len);
extern char * encoding_copyReturnType(const char *t);
extern void encoding_getArgumentType(const char *t, unsigned int index, char *dst, size_t dst_len);
extern char *encoding_copyArgumentType(const char *t, unsigned int index);

// sync.h
extern void _destroySyncCache(struct SyncCache *cache);

// arr
extern void arr_init(void);
extern id objc_autoreleaseReturnValue(id obj);

// block trampolines
extern IMP _imp_implementationWithBlockNoCopy(id block);

// layout.h
typedef struct {
    uint8_t *bits;
    size_t bitCount;
    size_t bitsAllocated;
    BOOL weak;
} layout_bitmap;
extern layout_bitmap layout_bitmap_create(const unsigned char *layout_string, size_t layoutStringInstanceSize, size_t instanceSize, BOOL weak);
extern layout_bitmap layout_bitmap_create_empty(size_t instanceSize, BOOL weak);
extern void layout_bitmap_free(layout_bitmap bits);
extern const unsigned char *layout_string_create(layout_bitmap bits);
extern void layout_bitmap_set_ivar(layout_bitmap bits, const char *type, size_t offset);
extern void layout_bitmap_grow(layout_bitmap *bits, size_t newCount);
extern void layout_bitmap_slide(layout_bitmap *bits, size_t oldPos, size_t newPos);
extern void layout_bitmap_slide_anywhere(layout_bitmap *bits, size_t oldPos, size_t newPos);
extern BOOL layout_bitmap_splat(layout_bitmap dst, layout_bitmap src,
                                size_t oldSrcInstanceSize);
extern BOOL layout_bitmap_or(layout_bitmap dst, layout_bitmap src, const char *msg);
extern BOOL layout_bitmap_clear(layout_bitmap dst, layout_bitmap src, const char *msg);
extern void layout_bitmap_print(layout_bitmap bits);


// fixme runtime
extern Class look_up_class(const char *aClassName, BOOL includeUnconnected, BOOL includeClassHandler);
extern const char *map_images();
extern const char *map_images_nolock();
extern const char * load_images();
extern BOOL load_images_nolock();
//extern void unmap_image(const struct mach_header *mh, intptr_t vmaddr_slide);
//extern void unmap_image_nolock(const struct mach_header *mh);
extern void _read_images(header_info **hList, uint32_t hCount);
extern void prepare_load_methods(header_info *hi);
//extern void _unload_image(header_info *hi);
extern const char ** _objc_copyClassNamesForImage(header_info *hi, unsigned int *outCount);


extern const header_info *_headerForClass(Class cls);

extern Class _class_remap(Class cls);
extern Class _class_getNonMetaClass(Class cls, id obj);
extern Ivar _class_getVariable(Class cls, const char *name, Class *memberOf);
extern BOOL _class_usesAutomaticRetainRelease(Class cls);
extern uint32_t _class_getInstanceStart(Class cls);

extern unsigned _class_createInstancesFromZone(Class cls, size_t extraBytes, void *zone, id *results, unsigned num_requested);
extern id _objc_constructOrFree(id bytes, Class cls);

extern const char *_category_getName(Category cat);
extern const char *_category_getClassName(Category cat);
extern Class _category_getClass(Category cat);
extern IMP _category_getLoadMethod(Category cat);

extern id object_cxxConstructFromClass(id obj, Class cls);
extern void object_cxxDestruct(id obj);

extern void _class_resolveMethod(Class cls, SEL sel, id inst);

#define OBJC_WARN_DEPRECATED \
    do { \
        static int warned = 0; \
        if (!warned) { \
            warned = 1; \
            _objc_inform_deprecated(__FUNCTION__, NULL); \
        } \
    } while (0) \

__END_DECLS


#ifndef STATIC_ASSERT
#   define STATIC_ASSERT(x) _STATIC_ASSERT2(x, __LINE__)
#   define _STATIC_ASSERT2(x, line) _STATIC_ASSERT3(x, line)
#   define _STATIC_ASSERT3(x, line)                                     \
        typedef struct {                                                \
            int _static_assert[(x) ? 0 : -1];                           \
        } _static_assert_ ## line __attribute__((unavailable))
#endif

#define countof(arr) (sizeof(arr) / sizeof((arr)[0]))


// Global operator new and delete. We must not use any app overrides.
// This ALSO REQUIRES each of these be in libobjc's unexported symbol list.
#if __cplusplus
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winline-new-delete"
#include <new>
inline void* operator new(std::size_t size) throw (std::bad_alloc) { return _malloc_internal(size); }
inline void* operator new[](std::size_t size) throw (std::bad_alloc) { return _malloc_internal(size); }
inline void* operator new(std::size_t size, const std::nothrow_t&) throw() { return _malloc_internal(size); }
inline void* operator new[](std::size_t size, const std::nothrow_t&) throw() { return _malloc_internal(size); }
inline void operator delete(void* p) throw() { _free_internal(p); }
inline void operator delete[](void* p) throw() { _free_internal(p); }
inline void operator delete(void* p, const std::nothrow_t&) throw() { _free_internal(p); }
inline void operator delete[](void* p, const std::nothrow_t&) throw() { _free_internal(p); }
#pragma clang diagnostic pop
#endif


// DisguisedPtr<T> acts like pointer type T*, except the
// stored value is disguised to hide it from tools like `leaks`.
// nil is disguised as itself so zero-filled memory works as expected,
// which means 0x80..00 is also diguised as itself but we don't care
template <typename T>
class DisguisedPtr {
    uintptr_t value;

    static uintptr_t disguise(T* ptr) {
        return -(uintptr_t)ptr;
    }

    static T* undisguise(uintptr_t val) {
        return (T*)-val;
    }

 public:
    DisguisedPtr() { }
    DisguisedPtr(T* ptr)
        : value(disguise(ptr)) { }
    DisguisedPtr(const DisguisedPtr<T>& ptr)
        : value(ptr.value) { }

    DisguisedPtr<T>& operator = (T* rhs) {
        value = disguise(rhs);
        return *this;
    }
    DisguisedPtr<T>& operator = (const DisguisedPtr<T>& rhs) {
        value = rhs.value;
        return *this;
    }

    operator T* () const {
        return undisguise(value);
    }
    T* operator -> () const {
        return undisguise(value);
    }
    T& operator * () const {
        return *undisguise(value);
    }
    T& operator [] (size_t i) const {
        return undisguise(value)[i];
    }

    // pointer arithmetic operators omitted
    // because we don't currently use them anywhere
};


// Pointer hash function.
// This is not a terrific hash, but it is fast
// and not outrageously flawed for our purposes.

// Based on principles from http://locklessinc.com/articles/fast_hash/
// and evaluation ideas from http://floodyberry.com/noncryptohashzoo/
#if __LP64__
static inline uint32_t ptr_hash(uint64_t key)
{
    key ^= key >> 4;
    key *= 0x8a970be7488fda55;
    key ^= __builtin_bswap64(key);
    return (uint32_t)key;
}
#else
static inline uint32_t ptr_hash(uint32_t key)
{
    key ^= key >> 4;
    key *= 0x5052acdb;
    key ^= __builtin_bswap32(key);
    return key;
}
#endif

/*
  Higher-quality hash function. This is measurably slower in some workloads.
#if __LP64__
 uint32_t ptr_hash(uint64_t key)
{
    key -= __builtin_bswap64(key);
    key *= 0x8a970be7488fda55;
    key ^= __builtin_bswap64(key);
    key *= 0x8a970be7488fda55;
    key ^= __builtin_bswap64(key);
    return (uint32_t)key;
}
#else
static uint32_t ptr_hash(uint32_t key)
{
    key -= __builtin_bswap32(key);
    key *= 0x5052acdb;
    key ^= __builtin_bswap32(key);
    key *= 0x5052acdb;
    key ^= __builtin_bswap32(key);
    return key;
}
#endif
*/


// Inlined parts of objc_object's implementation
#include "objc-object.h"

#endif /* _OBJC_PRIVATE_H_ */
