#ifndef SYCL_WASM3_STDIO_H
#define SYCL_WASM3_STDIO_H

#include <stdarg.h>
#include <stddef.h>

typedef struct __sycl_file FILE;

int printf(const char *fmt, ...);
int sprintf(char *buf, const char *fmt, ...);
int snprintf(char *buf, size_t n, const char *fmt, ...);
int vsnprintf(char *buf, size_t n, const char *fmt, va_list ap);

#endif

