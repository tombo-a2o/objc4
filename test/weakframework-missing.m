/*
 * Copyright (c) 2014-2017 Tombo Inc. All Rights Reserved.
 *
 * This source code is a modified version of the objc4 sources released by Apple Inc. under
 * the terms of the APSL version 2.0 (see below).
 *
 */

// TEST_CONFIG SDK=macosx,iphoneos

/*
TEST_BUILD
    $C{COMPILE} $DIR/weak2.m -DWEAK_FRAMEWORK=1 -DWEAK_IMPORT= -UEMPTY  -dynamiclib -o libweakframework.dylib

    $C{COMPILE} $DIR/weakframework-missing.m -L. -weak-lweakframework -o weakframework-missing.out

    $C{COMPILE} $DIR/weak2.m -DWEAK_FRAMEWORK=1 -DWEAK_IMPORT= -DEMPTY= -dynamiclib -o libweakframework.dylib

END
*/

#define WEAK_FRAMEWORK 1
#define WEAK_IMPORT
#include "weak.m"
