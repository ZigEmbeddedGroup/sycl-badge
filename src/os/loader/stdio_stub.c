#include "stdio.h"

int printf(const char *fmt, ...) {
    (void)fmt;
    return 0;
}

int sprintf(char *buf, const char *fmt, ...) {
    (void)fmt;
    if (buf) {
        buf[0] = 0;
    }
    return 0;
}

int snprintf(char *buf, size_t n, const char *fmt, ...) {
    (void)fmt;
    if (buf && n > 0) {
        buf[0] = 0;
    }
    return 0;
}

int vsnprintf(char *buf, size_t n, const char *fmt, va_list ap) {
    (void)fmt;
    (void)ap;
    if (buf && n > 0) {
        buf[0] = 0;
    }
    return 0;
}

