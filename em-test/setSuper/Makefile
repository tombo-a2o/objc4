OBJC4=../..

OBJS=$(OBJC4)/libobjc4.a $(OBJC4)/lib/libclosure-65/libclosure.a

INCLUDE=-I$(OBJC4)/include
CLANG_OPTS=-fblocks -fobjc-runtime=macosx
EM_OPTS=-s ASSERTIONS=0 -s DEMANGLE_SUPPORT=1 -s ERROR_ON_UNDEFINED_SYMBOLS=0
CFLAGS=$(INCLUDE) $(CLANG_OPTS) $(EM_OPTS)

CC=emcc

all:	setSuper.js

setSuper.js:	setSuper.m
	$(CC) -v $(CFLAGS) -o $@ $(OBJS) $<

setSuper.ll:	setSuper.m
	$(CC) -emit-llvm -S -o $@ $(CLANG_OPTS) $(INCLUDE) $<

setSuper:	setSuper.m
	clang -framework Foundation -fblocks -fobjc-runtime=macosx -o $@ $<
