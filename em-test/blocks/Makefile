OBJC4=../..

OBJS=$(OBJC4)/libobjc4.bc $(OBJC4)/lib/libclosure-65/libclosure.bc

INCLUDE=-I$(OBJC4)/include
CLANG_OPTS=-fblocks -fobjc-runtime=macosx
EM_OPTS=-s ASSERTIONS=0 -s DEMANGLE_SUPPORT=1 -s ERROR_ON_UNDEFINED_SYMBOLS=1 -s EXPORTED_FUNCTIONS='["_main", "__class_lookupMethodAndLoadCache3"]' --js-library $(OBJC4)/runtime/lib.js
CFLAGS=$(INCLUDE) $(CLANG_OPTS) $(EM_OPTS)

CC=emcc

all:	blocks.js

blocks.js:	blocks.m
	$(CC) $(CFLAGS) -o $@ $(OBJS) $<

blocks.ll:	blocks.m
	$(CC) -emit-llvm -S -o $@ $(CLANG_OPTS) $(INCLUDE) $<
