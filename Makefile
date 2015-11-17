BUILD ?= build/debug
LIB = $(BUILD)/libobjc4.a
SOURCES := $(addprefix runtime/, \
	hashtable2.mm \
	maptable.mm \
	objc-auto.mm \
	objc-cache.mm \
	objc-empty-vtable.m \
	objc-class-old.mm \
	objc-class.mm \
	objc-errors.mm \
	objc-exception.mm \
	objc-file.mm \
	objc-initialize.mm \
	objc-layout.mm \
	objc-load.mm \
	objc-loadmethod.mm \
	objc-lockdebug.mm \
	objc-runtime-new.mm \
	objc-runtime-old.mm \
	objc-runtime.mm \
	objc-sel-set.mm \
	objc-sel.mm \
	objc-sync.mm \
	objc-typeencoding.mm \
	Object.mm \
	Protocol.mm \
	OldClasses.subproj/List.m \
	Accessors.subproj/objc-accessors.mm \
	objc-references.mm \
	objc-os.mm \
	objc-auto-dump.mm \
	objc-file-old.mm \
	objc-externalref.mm \
	objc-weak.mm \
	NSObject.mm \
	objc-opt.mm \
	objc-cache-old.mm \
	objc-sel-old.mm \
)
OBJS = $(patsubst runtime/%, $(BUILD)/%, $(patsubst %.m, %.o, $(patsubst %.mm, %.o, $(SOURCES))))

PUBLIC_HEADERS = \
	include/objc/NSObjCRuntime.h \
	include/objc/NSObject.h \
	include/objc/message.h \
	include/objc/objc-api.h \
	include/objc/objc-auto.h \
	include/objc/objc-exception.h \
	include/objc/objc-sync.h \
	include/objc/objc.h \
	include/objc/runtime.h
PRIVATE_HEADERS = \
	include/objc/objc-internal.h \
	include/objc/objc-abi.h \
	include/objc/maptable.h \
	include/objc/objc-auto-dump.h \
	include/objc/objc-gdb.h
OBSOLETE_HEADERS= \
	include/objc/hashtable.h \
	include/objc/hashtable2.h \
	include/objc/objc-class.h \
	include/objc/objc-load.h \
	include/objc/objc-runtime.h \
	include/objc/List.h \
	include/objc/Object.h \
	include/objc/Protocol.h
HEADERS = $(PUBLIC_HEADERS) $(PRIVATE_HEADERS) $(OBSOLETE_HEADERS)
DEPS := $(OBJS:.o=.d)

CC = emcc
CXX = em++
LINK = emar
CFLAGS = -I./include -I./runtime -I./runtime/Accessors.subproj -fblocks -Wno-invalid-offsetof $(OPT_CFLAGS) --tracing

.SUFFIXES: .mm .m .o

all: $(LIB)

$(LIB): $(HEADERS) $(OBJS)
	llvm-link -o libobjc4.bc $(OBJS)
	rm -f $@
	$(LINK) rcs $@ libobjc4.bc

clean:
	rm -f $(LIB) $(HEADERS) $(OBJS) $(DEPS)

-include $(DEPS)

$(BUILD)/%.o: runtime/%.mm $(HEADERS)
	@mkdir -p $(@D)
	$(CXX) $(CFLAGS) -MMD -MP -MF $(@:%.o=%.d) -o $@ $<

$(BUILD)/%.o: runtime/%.m $(HEADERS)
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -MMD -MP -MF $(@:%.o=%.d) -o $@ $<

include/objc/%.h: runtime/%.h
	cp $< $@

install: $(LIB)
	cp $(LIB) $(EMSCRIPTEN)/system/local/lib/
	mkdir -p $(EMSCRIPTEN)/system/local/include/objc
	cp $(PUBLIC_HEADERS) $(EMSCRIPTEN)/system/local/include/objc/

.PHONY: all clean install

include/objc/NSObjCRuntime.h: runtime/NSObjCRuntime.h
include/objc/NSObject.h: runtime/NSObject.h
include/objc/message.h: runtime/message.h
include/objc/objc-api.h: runtime/objc-api.h
include/objc/objc-auto.h: runtime/objc-auto.h
include/objc/objc-exception.h: runtime/objc-exception.h
include/objc/objc-sync.h: runtime/objc-sync.h
include/objc/objc.h: runtime/objc.h
include/objc/runtime.h: runtime/runtime.h

include/objc/objc-internal.h: runtime/objc-internal.h
include/objc/objc-abi.h: runtime/objc-abi.h
include/objc/maptable.h: runtime/maptable.h
include/objc/objc-auto-dump.h: runtime/objc-auto-dump.h
include/objc/objc-gdb.h: runtime/objc-gdb.h

include/objc/hashtable.h: runtime/hashtable.h
include/objc/hashtable2.h: runtime/hashtable2.h
include/objc/objc-class.h: runtime/objc-class.h
include/objc/objc-load.h: runtime/objc-load.h
include/objc/objc-runtime.h: runtime/objc-runtime.h
include/objc/List.h: runtime/OldClasses.subproj/List.h
	cp $< $@
include/objc/Object.h: runtime/Object.h
include/objc/Protocol.h: runtime/Protocol.h
