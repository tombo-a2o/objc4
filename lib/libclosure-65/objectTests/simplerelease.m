/*
 * Copyright (c) 2010 Apple Inc. All rights reserved.
 *
 * @APPLE_LLVM_LICENSE_HEADER@
 */

// test non-GC -release of block-captured objects

// TEST_CONFIG MEM=mrc
// TEST_CFLAGS -framework Foundation

#import <Foundation/Foundation.h>
#import <Block_private.h>
#import "test.h"

int global = 0;

@interface TestObject : NSObject
@end
@implementation TestObject
- (oneway void)release {
    global = 1;
    [super release];
}
@end

int main() {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    TestObject *to = [[TestObject alloc] init];
    void (^b)(void) = ^{ printf("to is at %p\n", to); abort(); };

    // verify that b has a copy/dispose helper
    struct Block_layout *layout = (struct Block_layout *)(void *)b;
    if (!(layout->flags & BLOCK_HAS_COPY_DISPOSE)) {
        fail("Whoops, no copy dispose!");
    }
    struct Block_descriptor_2 *desc = 
        (struct Block_descriptor_2 *)(layout->descriptor + 1);
    if (!(desc->dispose)) {
        fail("Whoops, no block dispose helper function!");
    }
    desc->dispose(b);
    if (global != 1) {
	fail("Whoops, helper routine didn't release captive object");
    }
    [pool drain];

    succeed(__FILE__);
}
