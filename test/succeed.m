// TEST_CONFIG

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sys/param.h>
#include <libgen.h>

static inline void succeed(const char *name)
{
    if (name) {
        char path[MAXPATHLEN+1];
        strcpy(path, name);
        fprintf(stderr, "OK: %s\n", basename(path));
    } else {
        fprintf(stderr, "OK\n");
    }
    exit(0);
}

int main()
{
    succeed(__FILE__);
}
