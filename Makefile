LIB := libobjc4.bc
OBJS := \
	runtime/hashtable2.o \
	runtime/maptable.o \
	runtime/objc-auto.o \
	runtime/objc-cache.o \
	runtime/objc-empty-vtable.o \
	runtime/objc-class-old.o \
	runtime/objc-class.o \
	runtime/objc-errors.o \
	runtime/objc-exception.o \
	runtime/objc-file.o \
	runtime/objc-initialize.o \
	runtime/objc-layout.o \
	runtime/objc-load.o \
	runtime/objc-loadmethod.o \
	runtime/objc-lockdebug.o \
	runtime/objc-runtime-new.o \
	runtime/objc-runtime-old.o \
	runtime/objc-runtime.o \
	runtime/objc-sel-set.o \
	runtime/objc-sel.o \
	runtime/objc-sync.o \
	runtime/objc-typeencoding.o \
	runtime/Object.o \
	runtime/Protocol.o \
	runtime/OldClasses.subproj/List.o \
	runtime/Accessors.subproj/objc-accessors.o \
	runtime/objc-references.o \
	runtime/objc-os.o \
	runtime/objc-auto-dump.o \
	runtime/objc-file-old.o \
	runtime/objc-externalref.o \
	runtime/objc-weak.o \
	runtime/NSObject.o \
	runtime/objc-opt.o \
	runtime/objc-cache-old.o \
	runtime/objc-sel-old.o
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
LIBCLOSURE = libclosure

CC = emcc
LINK = llvm-link
CFLAGS = -I./include -I./runtime -I./runtime/Accessors.subproj -I./lib/libclosure-65 -fblocks -fobjc-runtime=macosx

.SUFFIXES: .mm .m .o

all: $(LIB) libclosure

$(LIB): $(HEADERS) $(OBJS)
	$(LINK) -o $@ $(OBJS)

libclosure:
	cd lib/libclosure-65 && $(MAKE)

clean:
	rm -f $(LIB) $(HEADERS) $(OBJS) $(DEPS)

-include $(DEPS)

.mm.o:
	$(CC) $(CFLAGS) -MMD -MP -MF $(@:%.o=%.d) -o $@ $<

.m.o:
	$(CC) $(CFLAGS) -MMD -MP -MF $(@:%.o=%.d) -o $@ $<

include/objc/%.h: runtime/%.h
	cp $< $@

.PHONY: all clean libclosure

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
