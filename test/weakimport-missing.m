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
    $C{COMPILE} $DIR/weak2.m -UWEAK_FRAMEWORK -DWEAK_IMPORT=__attribute__\\(\\(weak_import\\)\\) -UEMPTY  -dynamiclib -o libweakimport.dylib

    $C{COMPILE} $DIR/weakimport-missing.m -L. -weak-lweakimport -o weakimport-missing.out

    $C{COMPILE} $DIR/weak2.m -UWEAK_FRAMEWORK -DWEAK_IMPORT=__attribute__\\(\\(weak_import\\)\\)  -DEMPTY= -dynamiclib -o libweakimport.dylib
END
*/

// #define WEAK_FRAMEWORK
#define WEAK_IMPORT __attribute__((weak_import))
#include "weak.m"
