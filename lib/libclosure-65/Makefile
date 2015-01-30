LIB := libclosure.bc
OBJS := data.o runtime.o
DEPS := $(OBJS:.o=.d)

CC = emcc
LINK = llvm-link
CFLAGS = -I./ -I../../include

.SUFFIXES: .c .o

all: $(LIB)

$(LIB): $(HEADERS) $(OBJS)
	$(LINK) -o $@ $(OBJS)

clean:
	rm -f $(LIB) $(HEADERS) $(OBJS) $(DEPS)

-include $(DEPS)

.c.o:
	$(CC) $(CFLAGS) -MMD -MP -MF $(@:%.o=%.d) -o $@ $<

.PHONY: all clean
