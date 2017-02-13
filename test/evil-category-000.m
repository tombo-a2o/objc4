/*
 * Copyright (c) 2014-2017 Tombo Inc. All Rights Reserved.
 *
 * This source code is a modified version of the objc4 sources released by Apple Inc. under
 * the terms of the APSL version 2.0 (see below).
 *
 */

// TEST_CONFIG SDK=macosx,iphoneos
/*
rdar://8553305

TEST_BUILD
    $C{COMPILE} $DIR/evil-category-000.m -dynamiclib -o libevil.dylib
    $C{COMPILE} $DIR/evil-main.m -x none -DNOT_EVIL libevil.dylib -o evil-category-000.out
END
*/

// NOT EVIL version: category omitted from all lists

#define EVIL_INSTANCE_METHOD 1
#define EVIL_CLASS_METHOD 1

#define OMIT_CAT 1
#define OMIT_NL_CAT 1

#include "evil-category-def.m"
