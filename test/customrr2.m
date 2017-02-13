/*
 * Copyright (c) 2014-2017 Tombo Inc. All Rights Reserved.
 *
 * This source code is a modified version of the objc4 sources released by Apple Inc. under
 * the terms of the APSL version 2.0 (see below).
 *
 */

// These options must match customrr.m
// TEST_CONFIG MEM=mrc SDK=macosx,iphoneos
/*
TEST_BUILD
    $C{COMPILE} $DIR/customrr.m -fvisibility=default -o customrr2.out -DTEST_EXCHANGEIMPLEMENTATIONS=1
    $C{COMPILE} -undefined dynamic_lookup -dynamiclib $DIR/customrr-cat1.m -o customrr-cat1.dylib
    $C{COMPILE} -undefined dynamic_lookup -dynamiclib $DIR/customrr-cat2.m -o customrr-cat2.dylib
END
*/
