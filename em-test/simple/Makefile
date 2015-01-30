OBJC4=../..

OBJS=$(OBJC4)/libobjc4.bc $(OBJC4)/lib/libclosure-65/libclosure.bc

INCLUDE=-I$(OBJC4)/include
CLANG_OPTS=-fblocks -fobjc-runtime=macosx
EM_OPTS=-s ASSERTIONS=0 -s DEMANGLE_SUPPORT=1 -s ERROR_ON_UNDEFINED_SYMBOLS=1 -s EXPORTED_FUNCTIONS='["_main", "__class_lookupMethodAndLoadCache3"]' --js-library $(OBJC4)/runtime/lib.js
CFLAGS=$(INCLUDE) $(CLANG_OPTS) $(EM_OPTS)

CC=emcc

all:	minimum.js

minimum.js:	minimum.m
	$(CC) $(CFLAGS) -o $@ $(OBJS) $<
	#emcc -fblocks -fobjc-runtime=macosx -s ASSERTIONS=0 -s DEMANGLE_SUPPORT=1 -s ERROR_ON_UNDEFINED_SYMBOLS=1 -s EXPORTED_FUNCTIONS='["_main", "__class_lookupMethodAndLoadCache3"]' --js-library ../../runtime/lib.js -o minimum.js -I../../include $(OBJS) minimum.m
	#EMCC_DEBUG_SAVE=1 EMCC_DEBUG=1 emcc -v -g -O0 -fblocks -fobjc-runtime=macosx -s DEMANGLE_SUPPORT=1 -s ASSERTIONS=0 -s ERROR_ON_UNDEFINED_SYMBOLS=1 -s EXPORTED_FUNCTIONS='["_main", "__class_lookupMethodAndLoadCache3"]' --js-library ../../runtime/lib.js -o minimum.js -I../../include $(OBJS) minimum.m

minimum.ll:	minimum.m
	$(CC) -emit-llvm -S -o $@ $(CLANG_OPTS) $(INCLUDE) $<
