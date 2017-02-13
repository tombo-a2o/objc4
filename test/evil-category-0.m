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
    $C{COMPILE} $DIR/evil-category-0.m -dynamiclib -o libevil.dylib
    $C{COMPILE} $DIR/evil-main.m -x none -DNOT_EVIL libevil.dylib -o evil-category-0.out
END
*/

// NOT EVIL version

#define EVIL_INSTANCE_METHOD 0
#define EVIL_CLASS_METHOD 0

#define OMIT_CAT 0
#define OMIT_NL_CAT 0

#include "evil-category-def.m"
