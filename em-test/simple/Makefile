OBJC4=../..

INCLUDE=-I$(OBJC4)/include
CLANG_OPTS=-fblocks -fobjc-runtime=macosx

all:	minimum.js

minimum.js:	minimum.m
	a2o -o $@ $<

minimum_debug.js:	minimum.m
	a2o -o $@ $< --pre-js init.js

minimum.ll:	minimum.m
	clang -emit-llvm -S -o $@ $(CLANG_OPTS) $(INCLUDE) $<

minimum: minimum.m
	clang -framework Foundation -o $@ $<
