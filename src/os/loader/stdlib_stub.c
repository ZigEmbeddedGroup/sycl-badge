#include "stdlib.h"

unsigned long strtoul(const char *nptr, char **endptr, int base) {
    (void)nptr;
    (void)endptr;
    (void)base;
    return 0;
}

unsigned long long strtoull(const char *nptr, char **endptr, int base) {
    (void)nptr;
    (void)endptr;
    (void)base;
    return 0;
}

double strtod(const char *nptr, char **endptr) {
    (void)nptr;
    (void)endptr;
    return 0.0;
}

void abort(void) {
    for (;;) {}
}

