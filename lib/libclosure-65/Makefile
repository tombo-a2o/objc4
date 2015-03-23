LIB := libclosure.a
OBJS := data.o runtime.o
DEPS := $(OBJS:.o=.d)

CC = emcc
LINK = emar
CFLAGS = -I./ -I../../include

.SUFFIXES: .c .o

all: $(LIB)

$(LIB): $(HEADERS) $(OBJS)
	$(LINK) rcs $@ $(OBJS)

clean:
	rm -f $(LIB) $(HEADERS) $(OBJS) $(DEPS)

-include $(DEPS)

.c.o:
	$(CC) $(CFLAGS) -MMD -MP -MF $(@:%.o=%.d) -o $@ $<

install:
	cp libclosure.a $(EMSCRIPTEN)/system/local/lib/
	cp Block.h $(EMSCRIPTEN)/system/local/include/
	cp Block_private.h $(EMSCRIPTEN)/system/local/include/

.PHONY: all clean install
