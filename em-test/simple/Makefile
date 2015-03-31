OBJC4=../..

OBJS=$(OBJC4)/libobjc4.a $(OBJC4)/lib/libclosure-65/libclosure.a

INCLUDE=-I$(OBJC4)/include
CLANG_OPTS=-fblocks -fobjc-runtime=macosx
EM_OPTS=-s ASSERTIONS=0 -s DEMANGLE_SUPPORT=1 -s ERROR_ON_UNDEFINED_SYMBOLS=0
CFLAGS=$(INCLUDE) $(CLANG_OPTS) $(EM_OPTS)

CC=emcc

all:	minimum.js

minimum.js:	minimum.m
	$(CC) $(CFLAGS) -o $@ $(OBJS) $<

minimum_debug.js:	minimum.m
	$(CC) $(CFLAGS) -o $@ $(OBJS) $< --pre-js init.js

minimum.ll:	minimum.m
	$(CC) -emit-llvm -S -o $@ $(CLANG_OPTS) $(INCLUDE) $<

minimum: minimum.m
	clang -framework Foundation -o $@ $<
