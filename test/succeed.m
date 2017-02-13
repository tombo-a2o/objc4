/*
 * Copyright (c) 2014-2017 Tombo Inc. All Rights Reserved.
 *
 * This source code is a modified version of the objc4 sources released by Apple Inc. under
 * the terms of the APSL version 2.0 (see below).
 *
 */

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
