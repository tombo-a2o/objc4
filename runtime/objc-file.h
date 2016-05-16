/*
 * Copyright (c) 2009 Apple Inc.  All Rights Reserved.
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

#ifndef _OBJC_FILE_NEW_H
#define _OBJC_FILE_NEW_H

#if __OBJC2__

#include "objc-runtime-new.h"


__BEGIN_DECLS

#ifdef EMSCRIPTEN

extern SEL *_getObjc2SelectorRef(size_t idx);
extern message_ref_t *_getObjc2MessageRef(size_t idx);
extern Class *_getObjc2ClassRef(size_t idx);
extern Class *_getObjc2SuperRef(size_t idx);
extern classref_t *_getObjc2Class(size_t idx);
extern classref_t *_getObjc2NonlazyClass(size_t idx);
extern category_t **_getObjc2Category(size_t idx);
extern category_t **_getObjc2NonlazyCategory(size_t idx);
extern protocol_t **_getObjc2Protocol(size_t idx);
extern protocol_t **_getObjc2ProtocolRef(size_t idx);

extern size_t _getObjc2SelectorRefCount();
extern size_t _getObjc2MessageRefCount();
extern size_t _getObjc2ClassRefCount();
extern size_t _getObjc2SuperRefCount();
extern size_t _getObjc2ClassCount();
extern size_t _getObjc2NonlazyClassCount();
extern size_t _getObjc2CategoryCount();
extern size_t _getObjc2NonlazyCategoryCount();
extern size_t _getObjc2ProtocolCount();
extern size_t _getObjc2ProtocolRefCount();

#else
// classref_t is not fixed up at launch; use remapClass() to convert

extern SEL *_getObjc2SelectorRefs(const header_info *hi, size_t *count);
extern message_ref_t *_getObjc2MessageRefs(const header_info *hi, size_t *count);
extern Class*_getObjc2ClassRefs(const header_info *hi, size_t *count);
extern Class*_getObjc2SuperRefs(const header_info *hi, size_t *count);
extern classref_t *_getObjc2ClassList(const header_info *hi, size_t *count);
extern classref_t *_getObjc2NonlazyClassList(const header_info *hi, size_t *count);
extern category_t **_getObjc2CategoryList(const header_info *hi, size_t *count);
extern category_t **_getObjc2NonlazyCategoryList(const header_info *hi, size_t *count);
extern protocol_t **_getObjc2ProtocolList(const header_info *hi, size_t *count);
extern protocol_t **_getObjc2ProtocolRefs(const header_info *hi, size_t *count);

#endif

__END_DECLS

#endif

#endif
