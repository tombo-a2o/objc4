all:	setSuper.js

setSuper.js:	setSuper.m
	a2o -v -o $@ $<

INCLUDE=-I../../include
CLANG_OPTS=-fblocks -fobjc-runtime=macosx

setSuper.ll:	setSuper.m
	clang -emit-llvm -S -o $@ $(CLANG_OPTS) $(INCLUDE) $<

setSuper:	setSuper.m
	clang -framework Foundation -fblocks -fobjc-runtime=macosx -o $@ $<
