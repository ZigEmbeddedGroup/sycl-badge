pub const __builtin_bswap16 = @import("std").zig.c_builtins.__builtin_bswap16;
pub const __builtin_bswap32 = @import("std").zig.c_builtins.__builtin_bswap32;
pub const __builtin_bswap64 = @import("std").zig.c_builtins.__builtin_bswap64;
pub const __builtin_signbit = @import("std").zig.c_builtins.__builtin_signbit;
pub const __builtin_signbitf = @import("std").zig.c_builtins.__builtin_signbitf;
pub const __builtin_popcount = @import("std").zig.c_builtins.__builtin_popcount;
pub const __builtin_ctz = @import("std").zig.c_builtins.__builtin_ctz;
pub const __builtin_clz = @import("std").zig.c_builtins.__builtin_clz;
pub const __builtin_sqrt = @import("std").zig.c_builtins.__builtin_sqrt;
pub const __builtin_sqrtf = @import("std").zig.c_builtins.__builtin_sqrtf;
pub const __builtin_sin = @import("std").zig.c_builtins.__builtin_sin;
pub const __builtin_sinf = @import("std").zig.c_builtins.__builtin_sinf;
pub const __builtin_cos = @import("std").zig.c_builtins.__builtin_cos;
pub const __builtin_cosf = @import("std").zig.c_builtins.__builtin_cosf;
pub const __builtin_exp = @import("std").zig.c_builtins.__builtin_exp;
pub const __builtin_expf = @import("std").zig.c_builtins.__builtin_expf;
pub const __builtin_exp2 = @import("std").zig.c_builtins.__builtin_exp2;
pub const __builtin_exp2f = @import("std").zig.c_builtins.__builtin_exp2f;
pub const __builtin_log = @import("std").zig.c_builtins.__builtin_log;
pub const __builtin_logf = @import("std").zig.c_builtins.__builtin_logf;
pub const __builtin_log2 = @import("std").zig.c_builtins.__builtin_log2;
pub const __builtin_log2f = @import("std").zig.c_builtins.__builtin_log2f;
pub const __builtin_log10 = @import("std").zig.c_builtins.__builtin_log10;
pub const __builtin_log10f = @import("std").zig.c_builtins.__builtin_log10f;
pub const __builtin_abs = @import("std").zig.c_builtins.__builtin_abs;
pub const __builtin_labs = @import("std").zig.c_builtins.__builtin_labs;
pub const __builtin_llabs = @import("std").zig.c_builtins.__builtin_llabs;
pub const __builtin_fabs = @import("std").zig.c_builtins.__builtin_fabs;
pub const __builtin_fabsf = @import("std").zig.c_builtins.__builtin_fabsf;
pub const __builtin_floor = @import("std").zig.c_builtins.__builtin_floor;
pub const __builtin_floorf = @import("std").zig.c_builtins.__builtin_floorf;
pub const __builtin_ceil = @import("std").zig.c_builtins.__builtin_ceil;
pub const __builtin_ceilf = @import("std").zig.c_builtins.__builtin_ceilf;
pub const __builtin_trunc = @import("std").zig.c_builtins.__builtin_trunc;
pub const __builtin_truncf = @import("std").zig.c_builtins.__builtin_truncf;
pub const __builtin_round = @import("std").zig.c_builtins.__builtin_round;
pub const __builtin_roundf = @import("std").zig.c_builtins.__builtin_roundf;
pub const __builtin_strlen = @import("std").zig.c_builtins.__builtin_strlen;
pub const __builtin_strcmp = @import("std").zig.c_builtins.__builtin_strcmp;
pub const __builtin_object_size = @import("std").zig.c_builtins.__builtin_object_size;
pub const __builtin___memset_chk = @import("std").zig.c_builtins.__builtin___memset_chk;
pub const __builtin_memset = @import("std").zig.c_builtins.__builtin_memset;
pub const __builtin___memcpy_chk = @import("std").zig.c_builtins.__builtin___memcpy_chk;
pub const __builtin_memcpy = @import("std").zig.c_builtins.__builtin_memcpy;
pub const __builtin_expect = @import("std").zig.c_builtins.__builtin_expect;
pub const __builtin_nanf = @import("std").zig.c_builtins.__builtin_nanf;
pub const __builtin_huge_valf = @import("std").zig.c_builtins.__builtin_huge_valf;
pub const __builtin_inff = @import("std").zig.c_builtins.__builtin_inff;
pub const __builtin_isnan = @import("std").zig.c_builtins.__builtin_isnan;
pub const __builtin_isinf = @import("std").zig.c_builtins.__builtin_isinf;
pub const __builtin_isinf_sign = @import("std").zig.c_builtins.__builtin_isinf_sign;
pub const __has_builtin = @import("std").zig.c_builtins.__has_builtin;
pub const __builtin_assume = @import("std").zig.c_builtins.__builtin_assume;
pub const __builtin_unreachable = @import("std").zig.c_builtins.__builtin_unreachable;
pub const __builtin_constant_p = @import("std").zig.c_builtins.__builtin_constant_p;
pub const __builtin_mul_overflow = @import("std").zig.c_builtins.__builtin_mul_overflow;
pub const __builtin_va_list = [*c]u8;
pub const __gnuc_va_list = __builtin_va_list;
pub const va_list = __gnuc_va_list;
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw.h:610:3: warning: TODO implement translation of stmt class GCCAsmStmtClass

// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw.h:605:36: warning: unable to translate function, demoted to extern
pub extern fn __debugbreak() void;
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw.h:632:3: warning: TODO implement translation of stmt class GCCAsmStmtClass

// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw.h:626:60: warning: unable to translate function, demoted to extern
pub extern fn __fastfail(arg_code: c_uint) noreturn;
pub extern fn __mingw_get_crt_info() [*c]const u8;
pub const rsize_t = usize;
pub const ptrdiff_t = c_longlong;
pub const wchar_t = c_ushort;
pub const wint_t = c_ushort;
pub const wctype_t = c_ushort;
pub const errno_t = c_int;
pub const __time32_t = c_long;
pub const __time64_t = c_longlong;
pub const time_t = __time64_t;
pub const struct_threadlocaleinfostruct = extern struct {
    _locale_pctype: [*c]const c_ushort = @import("std").mem.zeroes([*c]const c_ushort),
    _locale_mb_cur_max: c_int = @import("std").mem.zeroes(c_int),
    _locale_lc_codepage: c_uint = @import("std").mem.zeroes(c_uint),
};
pub const struct_threadmbcinfostruct = opaque {};
pub const pthreadlocinfo = [*c]struct_threadlocaleinfostruct;
pub const pthreadmbcinfo = ?*struct_threadmbcinfostruct;
pub const struct___lc_time_data = opaque {};
pub const struct_localeinfo_struct = extern struct {
    locinfo: pthreadlocinfo = @import("std").mem.zeroes(pthreadlocinfo),
    mbcinfo: pthreadmbcinfo = @import("std").mem.zeroes(pthreadmbcinfo),
};
pub const _locale_tstruct = struct_localeinfo_struct;
pub const _locale_t = [*c]struct_localeinfo_struct;
pub const struct_tagLC_ID = extern struct {
    wLanguage: c_ushort = @import("std").mem.zeroes(c_ushort),
    wCountry: c_ushort = @import("std").mem.zeroes(c_ushort),
    wCodePage: c_ushort = @import("std").mem.zeroes(c_ushort),
};
pub const LC_ID = struct_tagLC_ID;
pub const LPLC_ID = [*c]struct_tagLC_ID;
pub const threadlocinfo = struct_threadlocaleinfostruct;
pub extern fn __local_stdio_printf_options() [*c]c_ulonglong;
pub extern fn __local_stdio_scanf_options() [*c]c_ulonglong;
pub const struct__iobuf = extern struct {
    _Placeholder: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
};
pub const FILE = struct__iobuf;
pub const _off_t = c_long;
pub const off32_t = c_long;
pub const _off64_t = c_longlong;
pub const off64_t = c_longlong;
pub const off_t = off32_t;
pub extern fn __acrt_iob_func(index: c_uint) [*c]FILE;
pub extern fn __iob_func() [*c]FILE;
pub const fpos_t = c_longlong;
pub extern fn __chk_fail() noreturn;
pub extern fn __mingw_chk_fail_warn() noreturn;
pub extern fn __mingw_sscanf(noalias _Src: [*c]const u8, noalias _Format: [*c]const u8, ...) c_int;
pub extern fn __mingw_vsscanf(noalias _Str: [*c]const u8, noalias Format: [*c]const u8, argp: va_list) c_int;
pub extern fn __mingw_scanf(noalias _Format: [*c]const u8, ...) c_int;
pub extern fn __mingw_vscanf(noalias Format: [*c]const u8, argp: va_list) c_int;
pub extern fn __mingw_fscanf(noalias _File: [*c]FILE, noalias _Format: [*c]const u8, ...) c_int;
pub extern fn __mingw_vfscanf(noalias fp: [*c]FILE, noalias Format: [*c]const u8, argp: va_list) c_int;
pub extern fn __mingw_vsnprintf(noalias _DstBuf: [*c]u8, _MaxCount: usize, noalias _Format: [*c]const u8, _ArgList: va_list) c_int;
pub extern fn __mingw_snprintf(noalias s: [*c]u8, n: usize, noalias format: [*c]const u8, ...) c_int;
pub extern fn __mingw_printf(noalias [*c]const u8, ...) c_int;
pub extern fn __mingw_vprintf(noalias [*c]const u8, va_list) c_int;
pub extern fn __mingw_fprintf(noalias [*c]FILE, noalias [*c]const u8, ...) c_int;
pub extern fn __mingw_vfprintf(noalias [*c]FILE, noalias [*c]const u8, va_list) c_int;
pub extern fn __mingw_sprintf(noalias [*c]u8, noalias [*c]const u8, ...) c_int;
pub extern fn __mingw_vsprintf(noalias [*c]u8, noalias [*c]const u8, va_list) c_int;
pub extern fn __mingw_asprintf(noalias [*c][*c]u8, noalias [*c]const u8, ...) c_int;
pub extern fn __mingw_vasprintf(noalias [*c][*c]u8, noalias [*c]const u8, va_list) c_int;
pub extern fn __ms_sscanf(noalias _Src: [*c]const u8, noalias _Format: [*c]const u8, ...) c_int;
pub extern fn __ms_vsscanf(noalias _Str: [*c]const u8, noalias _Format: [*c]const u8, argp: va_list) c_int;
pub extern fn __ms_scanf(noalias _Format: [*c]const u8, ...) c_int;
pub extern fn __ms_vscanf(noalias _Format: [*c]const u8, argp: va_list) c_int;
pub extern fn __ms_fscanf(noalias _File: [*c]FILE, noalias _Format: [*c]const u8, ...) c_int;
pub extern fn __ms_vfscanf(noalias _File: [*c]FILE, noalias _Format: [*c]const u8, argp: va_list) c_int;
pub extern fn __ms_printf(noalias [*c]const u8, ...) c_int;
pub extern fn __ms_vprintf(noalias [*c]const u8, va_list) c_int;
pub extern fn __ms_fprintf(noalias [*c]FILE, noalias [*c]const u8, ...) c_int;
pub extern fn __ms_vfprintf(noalias [*c]FILE, noalias [*c]const u8, va_list) c_int;
pub extern fn __ms_sprintf(noalias [*c]u8, noalias [*c]const u8, ...) c_int;
pub extern fn __ms_vsprintf(noalias [*c]u8, noalias [*c]const u8, va_list) c_int;
pub extern fn __ms_snprintf(noalias [*c]u8, usize, noalias [*c]const u8, ...) c_int;
pub extern fn __ms_vsnprintf(noalias [*c]u8, usize, noalias [*c]const u8, va_list) c_int;
pub extern fn __stdio_common_vsprintf(options: c_ulonglong, str: [*c]u8, len: usize, format: [*c]const u8, locale: _locale_t, valist: va_list) c_int;
pub extern fn __stdio_common_vfprintf(options: c_ulonglong, file: [*c]FILE, format: [*c]const u8, locale: _locale_t, valist: va_list) c_int;
pub extern fn __stdio_common_vsscanf(options: c_ulonglong, input: [*c]const u8, length: usize, format: [*c]const u8, locale: _locale_t, valist: va_list) c_int;
pub extern fn __stdio_common_vfscanf(options: c_ulonglong, file: [*c]FILE, format: [*c]const u8, locale: _locale_t, valist: va_list) c_int;
pub extern fn fprintf(noalias _File: [*c]FILE, noalias _Format: [*c]const u8, ...) c_int;
pub extern fn printf(_Format: [*c]const u8, ...) c_int;
pub extern fn sprintf(noalias _Dest: [*c]u8, noalias _Format: [*c]const u8, ...) c_int;
pub extern fn vfprintf(noalias _File: [*c]FILE, noalias _Format: [*c]const u8, _ArgList: __builtin_va_list) c_int;
pub extern fn vprintf(noalias _Format: [*c]const u8, _ArgList: __builtin_va_list) c_int;
pub inline fn vsprintf(noalias arg___stream: [*c]u8, noalias arg___format: [*c]const u8, arg___local_argv: __builtin_va_list) c_int {
    var __stream = arg___stream;
    _ = &__stream;
    var __format = arg___format;
    _ = &__format;
    var __local_argv = arg___local_argv;
    _ = &__local_argv;
    if (__builtin_object_size(@as(?*const anyopaque, @ptrCast(__stream)), @intFromBool((@as(c_int, 0) > @as(c_int, 0)) and (@as(c_int, 2) > @as(c_int, 1)))) != @as(usize, @bitCast(@as(c_longlong, -@as(c_int, 1))))) {
        var __retval: c_int = __mingw_call_vsnprintf(__stream, __builtin_object_size(@as(?*const anyopaque, @ptrCast(__stream)), @intFromBool((@as(c_int, 1) > @as(c_int, 0)) and (@as(c_int, 2) > @as(c_int, 1)))), __format, __local_argv);
        _ = &__retval;
        if (__retval >= @as(c_int, 0)) {
            _ = if (__builtin_expect(@as(c_long, @intFromBool(!(__builtin_object_size(@as(?*const anyopaque, @ptrCast(__stream)), @intFromBool((@as(c_int, 0) > @as(c_int, 0)) and (@as(c_int, 2) > @as(c_int, 1)))) != @as(usize, @bitCast(@as(c_longlong, -@as(c_int, 1))))) or (__builtin_object_size(@as(?*const anyopaque, @ptrCast(__stream)), @intFromBool((@as(c_int, 1) > @as(c_int, 0)) and (@as(c_int, 2) > @as(c_int, 1)))) >= (@as(usize, @bitCast(@as(c_longlong, __retval))) +% @as(usize, @bitCast(@as(c_longlong, @as(c_int, 1)))))))), @as(c_long, @bitCast(@as(c_long, @as(c_int, 1))))) != 0) @as(c_int, 0) else __chk_fail();
        }
        return __retval;
    }
    return __mingw_call_vsprintf(__stream, __format, __local_argv);
}
pub extern fn fscanf(noalias _File: [*c]FILE, noalias _Format: [*c]const u8, ...) c_int;
pub extern fn scanf(noalias _Format: [*c]const u8, ...) c_int;
pub extern fn sscanf(noalias _Src: [*c]const u8, noalias _Format: [*c]const u8, ...) c_int;
pub extern fn vfscanf(noalias __stream: [*c]FILE, noalias __format: [*c]const u8, __local_argv: __builtin_va_list) c_int;
pub extern fn vsscanf(noalias __source: [*c]const u8, noalias __format: [*c]const u8, __local_argv: __builtin_va_list) c_int;
pub extern fn vscanf(noalias __format: [*c]const u8, __local_argv: __builtin_va_list) c_int;
pub extern fn _filbuf(_File: [*c]FILE) c_int;
pub extern fn _flsbuf(_Ch: c_int, _File: [*c]FILE) c_int;
pub extern fn _fsopen(_Filename: [*c]const u8, _Mode: [*c]const u8, _ShFlag: c_int) [*c]FILE;
pub extern fn clearerr(_File: [*c]FILE) void;
pub extern fn fclose(_File: [*c]FILE) c_int;
pub extern fn _fcloseall() c_int;
pub extern fn _fdopen(_FileHandle: c_int, _Mode: [*c]const u8) [*c]FILE;
pub extern fn feof(_File: [*c]FILE) c_int;
pub extern fn ferror(_File: [*c]FILE) c_int;
pub extern fn fflush(_File: [*c]FILE) c_int;
pub extern fn fgetc(_File: [*c]FILE) c_int;
pub extern fn _fgetchar() c_int;
pub extern fn fgetpos(noalias _File: [*c]FILE, noalias _Pos: [*c]fpos_t) c_int;
pub extern fn fgetpos64(noalias _File: [*c]FILE, noalias _Pos: [*c]fpos_t) c_int;
pub inline fn fgets(noalias arg___dst: [*c]u8, arg___n: c_int, noalias arg___f: [*c]FILE) [*c]u8 {
    var __dst = arg___dst;
    _ = &__dst;
    var __n = arg___n;
    _ = &__n;
    var __f = arg___f;
    _ = &__f;
    _ = if (((__builtin_object_size(@as(?*const anyopaque, @ptrCast(__dst)), @intFromBool((@as(c_int, 0) > @as(c_int, 0)) and (@as(c_int, 2) > @as(c_int, 1)))) != @as(usize, @bitCast(@as(c_longlong, -@as(c_int, 1))))) and (__builtin_constant_p(__builtin_object_size(@as(?*const anyopaque, @ptrCast(__dst)), @intFromBool((@as(c_int, 1) > @as(c_int, 0)) and (@as(c_int, 2) > @as(c_int, 1)))) < @as(usize, @bitCast(@as(c_longlong, __n)))) != 0)) and (__builtin_object_size(@as(?*const anyopaque, @ptrCast(__dst)), @intFromBool((@as(c_int, 1) > @as(c_int, 0)) and (@as(c_int, 2) > @as(c_int, 1)))) < @as(usize, @bitCast(@as(c_longlong, __n))))) __mingw_chk_fail_warn() else if (__builtin_expect(@as(c_long, @intFromBool(!(__builtin_object_size(@as(?*const anyopaque, @ptrCast(__dst)), @intFromBool((@as(c_int, 0) > @as(c_int, 0)) and (@as(c_int, 2) > @as(c_int, 1)))) != @as(usize, @bitCast(@as(c_longlong, -@as(c_int, 1))))) or (__builtin_object_size(@as(?*const anyopaque, @ptrCast(__dst)), @intFromBool((@as(c_int, 1) > @as(c_int, 0)) and (@as(c_int, 2) > @as(c_int, 1)))) >= @as(usize, @bitCast(@as(c_longlong, __n)))))), @as(c_long, @bitCast(@as(c_long, @as(c_int, 1))))) != 0) @as(c_int, 0) else __chk_fail();
    return __mingw_call_fgets(__dst, __n, __f);
}
pub extern fn _fileno(_File: [*c]FILE) c_int;
pub extern fn _tempnam(_DirName: [*c]const u8, _FilePrefix: [*c]const u8) [*c]u8;
pub extern fn _flushall() c_int;
pub extern fn fopen(_Filename: [*c]const u8, _Mode: [*c]const u8) [*c]FILE;
pub extern fn fopen64(noalias filename: [*c]const u8, noalias mode: [*c]const u8) [*c]FILE;
pub extern fn fputc(_Ch: c_int, _File: [*c]FILE) c_int;
pub extern fn _fputchar(_Ch: c_int) c_int;
pub extern fn fputs(noalias _Str: [*c]const u8, noalias _File: [*c]FILE) c_int;
pub inline fn fread(arg___dst: ?*anyopaque, arg___sz: c_ulonglong, arg___n: c_ulonglong, arg___f: [*c]FILE) c_ulonglong {
    var __dst = arg___dst;
    _ = &__dst;
    var __sz = arg___sz;
    _ = &__sz;
    var __n = arg___n;
    _ = &__n;
    var __f = arg___f;
    _ = &__f;
    _ = if (((__builtin_object_size(__dst, @intFromBool((@as(c_int, 0) > @as(c_int, 0)) and (@as(c_int, 2) > @as(c_int, 1)))) != @as(usize, @bitCast(@as(c_longlong, -@as(c_int, 1))))) and (__builtin_constant_p(__builtin_object_size(__dst, @intFromBool((@as(c_int, 0) > @as(c_int, 0)) and (@as(c_int, 2) > @as(c_int, 1)))) < (__sz *% __n)) != 0)) and (__builtin_object_size(__dst, @intFromBool((@as(c_int, 0) > @as(c_int, 0)) and (@as(c_int, 2) > @as(c_int, 1)))) < (__sz *% __n))) __mingw_chk_fail_warn() else if (__builtin_expect(@as(c_long, @intFromBool(!(__builtin_object_size(__dst, @intFromBool((@as(c_int, 0) > @as(c_int, 0)) and (@as(c_int, 2) > @as(c_int, 1)))) != @as(usize, @bitCast(@as(c_longlong, -@as(c_int, 1))))) or (__builtin_object_size(__dst, @intFromBool((@as(c_int, 0) > @as(c_int, 0)) and (@as(c_int, 2) > @as(c_int, 1)))) >= (__sz *% __n)))), @as(c_long, @bitCast(@as(c_long, @as(c_int, 1))))) != 0) @as(c_int, 0) else __chk_fail();
    return __mingw_call_fread(__dst, __sz, __n, __f);
}
pub extern fn freopen(noalias _Filename: [*c]const u8, noalias _Mode: [*c]const u8, noalias _File: [*c]FILE) [*c]FILE;
pub extern fn fsetpos(_File: [*c]FILE, _Pos: [*c]const fpos_t) c_int;
pub extern fn fsetpos64(_File: [*c]FILE, _Pos: [*c]const fpos_t) c_int;
pub extern fn fseek(_File: [*c]FILE, _Offset: c_long, _Origin: c_int) c_int;
pub extern fn ftell(_File: [*c]FILE) c_long;
pub extern fn _fseeki64(_File: [*c]FILE, _Offset: c_longlong, _Origin: c_int) c_int;
pub extern fn _ftelli64(_File: [*c]FILE) c_longlong;
pub fn fseeko(arg__File: [*c]FILE, arg__Offset: _off_t, arg__Origin: c_int) callconv(.c) c_int {
    var _File = arg__File;
    _ = &_File;
    var _Offset = arg__Offset;
    _ = &_Offset;
    var _Origin = arg__Origin;
    _ = &_Origin;
    return fseek(_File, _Offset, _Origin);
}
pub fn fseeko64(arg__File: [*c]FILE, arg__Offset: _off64_t, arg__Origin: c_int) callconv(.c) c_int {
    var _File = arg__File;
    _ = &_File;
    var _Offset = arg__Offset;
    _ = &_Offset;
    var _Origin = arg__Origin;
    _ = &_Origin;
    return _fseeki64(_File, _Offset, _Origin);
}
pub fn ftello(arg__File: [*c]FILE) callconv(.c) _off_t {
    var _File = arg__File;
    _ = &_File;
    return ftell(_File);
}
pub fn ftello64(arg__File: [*c]FILE) callconv(.c) _off64_t {
    var _File = arg__File;
    _ = &_File;
    return _ftelli64(_File);
}
pub extern fn fwrite(_Str: ?*const anyopaque, _Size: c_ulonglong, _Count: c_ulonglong, _File: [*c]FILE) c_ulonglong;
pub extern fn getc(_File: [*c]FILE) c_int;
pub extern fn getchar() c_int;
pub extern fn _getmaxstdio() c_int;
pub inline fn gets(arg___dst: [*c]u8) [*c]u8 {
    var __dst = arg___dst;
    _ = &__dst;
    if (__builtin_object_size(@as(?*const anyopaque, @ptrCast(__dst)), @intFromBool((@as(c_int, 0) > @as(c_int, 0)) and (@as(c_int, 2) > @as(c_int, 1)))) != @as(usize, @bitCast(@as(c_longlong, -@as(c_int, 1))))) return __gets_chk(__dst, __builtin_object_size(@as(?*const anyopaque, @ptrCast(__dst)), @intFromBool((@as(c_int, 1) > @as(c_int, 0)) and (@as(c_int, 2) > @as(c_int, 1)))));
    return __mingw_call_gets_warn(__dst);
}
pub extern fn _getw(_File: [*c]FILE) c_int;
pub extern fn perror(_ErrMsg: [*c]const u8) void;
pub extern fn _pclose(_File: [*c]FILE) c_int;
pub extern fn _popen(_Command: [*c]const u8, _Mode: [*c]const u8) [*c]FILE;
pub extern fn putc(_Ch: c_int, _File: [*c]FILE) c_int;
pub extern fn putchar(_Ch: c_int) c_int;
pub extern fn puts(_Str: [*c]const u8) c_int;
pub extern fn _putw(_Word: c_int, _File: [*c]FILE) c_int;
pub extern fn remove(_Filename: [*c]const u8) c_int;
pub extern fn rename(_OldFilename: [*c]const u8, _NewFilename: [*c]const u8) c_int;
pub extern fn _unlink(_Filename: [*c]const u8) c_int;
pub extern fn unlink(_Filename: [*c]const u8) c_int;
pub extern fn rewind(_File: [*c]FILE) void;
pub extern fn _rmtmp() c_int;
pub extern fn setbuf(noalias _File: [*c]FILE, noalias _Buffer: [*c]u8) void;
pub extern fn _setmaxstdio(_Max: c_int) c_int;
pub extern fn _set_output_format(_Format: c_uint) c_uint;
pub extern fn _get_output_format() c_uint;
pub extern fn setvbuf(noalias _File: [*c]FILE, noalias _Buf: [*c]u8, _Mode: c_int, _Size: usize) c_int;
pub extern fn _scprintf(noalias _Format: [*c]const u8, ...) c_int;
pub extern fn _snscanf(noalias _Src: [*c]const u8, _MaxCount: usize, noalias _Format: [*c]const u8, ...) c_int;
pub extern fn _vscprintf(noalias _Format: [*c]const u8, _ArgList: va_list) c_int;
pub extern fn tmpfile() [*c]FILE;
pub inline fn tmpnam(arg___dst: [*c]u8) [*c]u8 {
    var __dst = arg___dst;
    _ = &__dst;
    _ = if (((__builtin_object_size(@as(?*const anyopaque, @ptrCast(__dst)), @intFromBool((@as(c_int, 0) > @as(c_int, 0)) and (@as(c_int, 2) > @as(c_int, 1)))) != @as(usize, @bitCast(@as(c_longlong, -@as(c_int, 1))))) and (__builtin_constant_p(__builtin_object_size(@as(?*const anyopaque, @ptrCast(__dst)), @intFromBool((@as(c_int, 1) > @as(c_int, 0)) and (@as(c_int, 2) > @as(c_int, 1)))) < @as(usize, @bitCast(@as(c_longlong, @as(c_int, 260))))) != 0)) and (__builtin_object_size(@as(?*const anyopaque, @ptrCast(__dst)), @intFromBool((@as(c_int, 1) > @as(c_int, 0)) and (@as(c_int, 2) > @as(c_int, 1)))) < @as(usize, @bitCast(@as(c_longlong, @as(c_int, 260)))))) __mingw_chk_fail_warn() else if (__builtin_expect(@as(c_long, @intFromBool(!(__builtin_object_size(@as(?*const anyopaque, @ptrCast(__dst)), @intFromBool((@as(c_int, 0) > @as(c_int, 0)) and (@as(c_int, 2) > @as(c_int, 1)))) != @as(usize, @bitCast(@as(c_longlong, -@as(c_int, 1))))) or (__builtin_object_size(@as(?*const anyopaque, @ptrCast(__dst)), @intFromBool((@as(c_int, 1) > @as(c_int, 0)) and (@as(c_int, 2) > @as(c_int, 1)))) >= @as(usize, @bitCast(@as(c_longlong, @as(c_int, 260))))))), @as(c_long, @bitCast(@as(c_long, @as(c_int, 1))))) != 0) @as(c_int, 0) else __chk_fail();
    return __mingw_call_tmpnam(__dst);
}
pub extern fn ungetc(_Ch: c_int, _File: [*c]FILE) c_int;
pub extern fn _vsnprintf(noalias _Dest: [*c]u8, _Count: usize, noalias _Format: [*c]const u8, _Args: va_list) c_int;
pub extern fn _snprintf(noalias _Dest: [*c]u8, _Count: usize, noalias _Format: [*c]const u8, ...) c_int;
pub extern fn __gets_chk([*c]u8, usize) [*c]u8;
pub extern fn __mingw_call_gets_warn([*c]u8) [*c]u8;
pub extern fn __mingw_call_fgets(noalias [*c]u8, c_int, noalias [*c]FILE) [*c]u8;
pub extern fn __mingw_call_fread(noalias ?*anyopaque, usize, usize, noalias [*c]FILE) usize;
pub extern fn __mingw_call_tmpnam([*c]u8) [*c]u8;
pub inline fn vsnprintf(noalias arg___stream: [*c]u8, arg___n: c_ulonglong, noalias arg___format: [*c]const u8, arg___local_argv: __builtin_va_list) c_int {
    var __stream = arg___stream;
    _ = &__stream;
    var __n = arg___n;
    _ = &__n;
    var __format = arg___format;
    _ = &__format;
    var __local_argv = arg___local_argv;
    _ = &__local_argv;
    _ = if (((__builtin_object_size(@as(?*const anyopaque, @ptrCast(__stream)), @intFromBool((@as(c_int, 0) > @as(c_int, 0)) and (@as(c_int, 2) > @as(c_int, 1)))) != @as(usize, @bitCast(@as(c_longlong, -@as(c_int, 1))))) and (__builtin_constant_p(__builtin_object_size(@as(?*const anyopaque, @ptrCast(__stream)), @intFromBool((@as(c_int, 1) > @as(c_int, 0)) and (@as(c_int, 2) > @as(c_int, 1)))) < __n) != 0)) and (__builtin_object_size(@as(?*const anyopaque, @ptrCast(__stream)), @intFromBool((@as(c_int, 1) > @as(c_int, 0)) and (@as(c_int, 2) > @as(c_int, 1)))) < __n)) __mingw_chk_fail_warn() else if (__builtin_expect(@as(c_long, @intFromBool(!(__builtin_object_size(@as(?*const anyopaque, @ptrCast(__stream)), @intFromBool((@as(c_int, 0) > @as(c_int, 0)) and (@as(c_int, 2) > @as(c_int, 1)))) != @as(usize, @bitCast(@as(c_longlong, -@as(c_int, 1))))) or (__builtin_object_size(@as(?*const anyopaque, @ptrCast(__stream)), @intFromBool((@as(c_int, 1) > @as(c_int, 0)) and (@as(c_int, 2) > @as(c_int, 1)))) >= __n))), @as(c_long, @bitCast(@as(c_long, @as(c_int, 1))))) != 0) @as(c_int, 0) else __chk_fail();
    return __mingw_call_vsnprintf(__stream, __n, __format, __local_argv);
}
pub extern fn snprintf(noalias __stream: [*c]u8, __n: c_ulonglong, noalias __format: [*c]const u8, ...) c_int;
pub extern fn __mingw_call_vsprintf(noalias __stream: [*c]u8, noalias __format: [*c]const u8, __local_argv: va_list) c_int;
pub extern fn __mingw_call_vsnprintf(noalias __stream: [*c]u8, __n: usize, noalias __format: [*c]const u8, __local_argv: va_list) c_int;
pub extern fn _set_printf_count_output(_Value: c_int) c_int;
pub extern fn _get_printf_count_output() c_int;
pub extern fn __mingw_swscanf(noalias _Src: [*c]const wchar_t, noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn __mingw_vswscanf(noalias _Str: [*c]const wchar_t, noalias Format: [*c]const wchar_t, argp: va_list) c_int;
pub extern fn __mingw_wscanf(noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn __mingw_vwscanf(noalias Format: [*c]const wchar_t, argp: va_list) c_int;
pub extern fn __mingw_fwscanf(noalias _File: [*c]FILE, noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn __mingw_vfwscanf(noalias fp: [*c]FILE, noalias Format: [*c]const wchar_t, argp: va_list) c_int;
pub extern fn __mingw_fwprintf(noalias _File: [*c]FILE, noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn __mingw_wprintf(noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn __mingw_vfwprintf(noalias _File: [*c]FILE, noalias _Format: [*c]const wchar_t, _ArgList: va_list) c_int;
pub extern fn __mingw_vwprintf(noalias _Format: [*c]const wchar_t, _ArgList: va_list) c_int;
pub extern fn __mingw_snwprintf(noalias s: [*c]wchar_t, n: usize, noalias format: [*c]const wchar_t, ...) c_int;
pub extern fn __mingw_vsnwprintf(noalias [*c]wchar_t, usize, noalias [*c]const wchar_t, va_list) c_int;
pub extern fn __mingw_swprintf(noalias [*c]wchar_t, usize, noalias [*c]const wchar_t, ...) c_int;
pub extern fn __mingw_vswprintf(noalias [*c]wchar_t, usize, noalias [*c]const wchar_t, va_list) c_int;
pub extern fn __ms_swscanf(noalias _Src: [*c]const wchar_t, noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn __ms_vswscanf(noalias _Src: [*c]const wchar_t, noalias _Format: [*c]const wchar_t, va_list) c_int;
pub extern fn __ms_wscanf(noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn __ms_vwscanf(noalias _Format: [*c]const wchar_t, va_list) c_int;
pub extern fn __ms_fwscanf(noalias _File: [*c]FILE, noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn __ms_vfwscanf(noalias _File: [*c]FILE, noalias _Format: [*c]const wchar_t, va_list) c_int;
pub extern fn __ms_fwprintf(noalias _File: [*c]FILE, noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn __ms_wprintf(noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn __ms_vfwprintf(noalias _File: [*c]FILE, noalias _Format: [*c]const wchar_t, _ArgList: va_list) c_int;
pub extern fn __ms_vwprintf(noalias _Format: [*c]const wchar_t, _ArgList: va_list) c_int;
pub extern fn __ms_swprintf(noalias [*c]wchar_t, usize, noalias [*c]const wchar_t, ...) c_int;
pub extern fn __ms_vswprintf(noalias [*c]wchar_t, usize, noalias [*c]const wchar_t, va_list) c_int;
pub extern fn __ms_snwprintf(noalias [*c]wchar_t, usize, noalias [*c]const wchar_t, ...) c_int;
pub extern fn __ms_vsnwprintf(noalias [*c]wchar_t, usize, noalias [*c]const wchar_t, va_list) c_int;
pub extern fn __stdio_common_vswprintf(options: c_ulonglong, str: [*c]wchar_t, len: usize, format: [*c]const wchar_t, locale: _locale_t, valist: va_list) c_int;
pub extern fn __stdio_common_vfwprintf(options: c_ulonglong, file: [*c]FILE, format: [*c]const wchar_t, locale: _locale_t, valist: va_list) c_int;
pub extern fn __stdio_common_vswscanf(options: c_ulonglong, input: [*c]const wchar_t, length: usize, format: [*c]const wchar_t, locale: _locale_t, valist: va_list) c_int;
pub extern fn __stdio_common_vfwscanf(options: c_ulonglong, file: [*c]FILE, format: [*c]const wchar_t, locale: _locale_t, valist: va_list) c_int;
pub extern fn fwscanf(noalias _File: [*c]FILE, noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn swscanf(noalias _Src: [*c]const wchar_t, noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn wscanf(noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn vfwscanf(__stream: [*c]FILE, __format: [*c]const wchar_t, __local_argv: va_list) c_int;
pub extern fn vswscanf(noalias __source: [*c]const wchar_t, noalias __format: [*c]const wchar_t, __local_argv: va_list) c_int;
pub extern fn vwscanf(__format: [*c]const wchar_t, __local_argv: va_list) c_int;
pub extern fn fwprintf(noalias _File: [*c]FILE, noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn wprintf(noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn vfwprintf(noalias _File: [*c]FILE, noalias _Format: [*c]const wchar_t, _ArgList: va_list) c_int;
pub extern fn vwprintf(noalias _Format: [*c]const wchar_t, _ArgList: va_list) c_int;
pub extern fn _wfsopen(_Filename: [*c]const wchar_t, _Mode: [*c]const wchar_t, _ShFlag: c_int) [*c]FILE;
pub extern fn fgetwc(_File: [*c]FILE) wint_t;
pub extern fn _fgetwchar() wint_t;
pub extern fn fputwc(_Ch: wchar_t, _File: [*c]FILE) wint_t;
pub extern fn _fputwchar(_Ch: wchar_t) wint_t;
pub extern fn getwc(_File: [*c]FILE) wint_t;
pub extern fn getwchar() wint_t;
pub extern fn putwc(_Ch: wchar_t, _File: [*c]FILE) wint_t;
pub extern fn putwchar(_Ch: wchar_t) wint_t;
pub extern fn ungetwc(_Ch: wint_t, _File: [*c]FILE) wint_t;
pub extern fn fgetws(noalias _Dst: [*c]wchar_t, _SizeInWords: c_int, noalias _File: [*c]FILE) [*c]wchar_t;
pub extern fn fputws(noalias _Str: [*c]const wchar_t, noalias _File: [*c]FILE) c_int;
pub extern fn _getws(_String: [*c]wchar_t) [*c]wchar_t;
pub extern fn _putws(_Str: [*c]const wchar_t) c_int;
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/stdio.h:1169:15: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _scwprintf(noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn _snwprintf(noalias _Dest: [*c]wchar_t, _Count: usize, noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn _vsnwprintf(noalias _Dest: [*c]wchar_t, _Count: usize, noalias _Format: [*c]const wchar_t, _Args: va_list) c_int;
pub extern fn swprintf(noalias _Dest: [*c]wchar_t, _Count: usize, noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn vswprintf(noalias _Dest: [*c]wchar_t, _Count: usize, noalias _Format: [*c]const wchar_t, _Args: va_list) c_int;
pub extern fn snwprintf(noalias s: [*c]wchar_t, n: usize, noalias format: [*c]const wchar_t, ...) c_int;
pub extern fn vsnwprintf(noalias s: [*c]wchar_t, n: usize, noalias format: [*c]const wchar_t, arg: va_list) c_int;
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/stdio.h:1190:15: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _swprintf(noalias _Dest: [*c]wchar_t, noalias _Format: [*c]const wchar_t, ...) c_int;
pub fn _vswprintf(noalias arg__Dest: [*c]wchar_t, noalias arg__Format: [*c]const wchar_t, arg__Args: va_list) callconv(.c) c_int {
    var _Dest = arg__Dest;
    _ = &_Dest;
    var _Format = arg__Format;
    _ = &_Format;
    var _Args = arg__Args;
    _ = &_Args;
    return __stdio_common_vswprintf(__local_stdio_printf_options().*, _Dest, @as(usize, @bitCast(@as(c_longlong, -@as(c_int, 1)))), _Format, null, _Args);
}
pub fn _vscwprintf(noalias arg__Format: [*c]const wchar_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    var _Result: c_int = __stdio_common_vswprintf(__local_stdio_printf_options().* | @as(c_ulonglong, 2), null, @as(usize, @bitCast(@as(c_longlong, @as(c_int, 0)))), _Format, null, _ArgList);
    _ = &_Result;
    return if (_Result < @as(c_int, 0)) -@as(c_int, 1) else _Result;
}
pub extern fn _wtempnam(_Directory: [*c]const wchar_t, _FilePrefix: [*c]const wchar_t) [*c]wchar_t;
pub extern fn _snwscanf(noalias _Src: [*c]const wchar_t, _MaxCount: usize, noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn _wfdopen(_FileHandle: c_int, _Mode: [*c]const wchar_t) [*c]FILE;
pub extern fn _wfopen(noalias _Filename: [*c]const wchar_t, noalias _Mode: [*c]const wchar_t) [*c]FILE;
pub extern fn _wfreopen(noalias _Filename: [*c]const wchar_t, noalias _Mode: [*c]const wchar_t, noalias _OldFile: [*c]FILE) [*c]FILE;
pub extern fn _wperror(_ErrMsg: [*c]const wchar_t) void;
pub extern fn _wpopen(_Command: [*c]const wchar_t, _Mode: [*c]const wchar_t) [*c]FILE;
pub extern fn _wremove(_Filename: [*c]const wchar_t) c_int;
pub extern fn _wtmpnam(_Buffer: [*c]wchar_t) [*c]wchar_t;
pub extern fn _fgetwc_nolock(_File: [*c]FILE) wint_t;
pub extern fn _fputwc_nolock(_Ch: wchar_t, _File: [*c]FILE) wint_t;
pub extern fn _ungetwc_nolock(_Ch: wint_t, _File: [*c]FILE) wint_t;
pub extern fn _fgetc_nolock(_File: [*c]FILE) c_int;
pub extern fn _fputc_nolock(_Char: c_int, _File: [*c]FILE) c_int;
pub extern fn _getc_nolock(_File: [*c]FILE) c_int;
pub extern fn _putc_nolock(_Char: c_int, _File: [*c]FILE) c_int;
pub extern fn _lock_file(_File: [*c]FILE) void;
pub extern fn _unlock_file(_File: [*c]FILE) void;
pub extern fn _fclose_nolock(_File: [*c]FILE) c_int;
pub extern fn _fflush_nolock(_File: [*c]FILE) c_int;
pub extern fn _fread_nolock(noalias _DstBuf: ?*anyopaque, _ElementSize: usize, _Count: usize, noalias _File: [*c]FILE) usize;
pub extern fn _fseek_nolock(_File: [*c]FILE, _Offset: c_long, _Origin: c_int) c_int;
pub extern fn _ftell_nolock(_File: [*c]FILE) c_long;
pub extern fn _fseeki64_nolock(_File: [*c]FILE, _Offset: c_longlong, _Origin: c_int) c_int;
pub extern fn _ftelli64_nolock(_File: [*c]FILE) c_longlong;
pub extern fn _fwrite_nolock(noalias _DstBuf: ?*const anyopaque, _Size: usize, _Count: usize, noalias _File: [*c]FILE) usize;
pub extern fn _ungetc_nolock(_Ch: c_int, _File: [*c]FILE) c_int;
pub extern fn tempnam(_Directory: [*c]const u8, _FilePrefix: [*c]const u8) [*c]u8;
pub extern fn fcloseall() c_int;
pub extern fn fdopen(_FileHandle: c_int, _Format: [*c]const u8) [*c]FILE;
pub extern fn fgetchar() c_int;
pub extern fn fileno(_File: [*c]FILE) c_int;
pub extern fn flushall() c_int;
pub extern fn fputchar(_Ch: c_int) c_int;
pub extern fn getw(_File: [*c]FILE) c_int;
pub extern fn putw(_Ch: c_int, _File: [*c]FILE) c_int;
pub extern fn rmtmp() c_int;
pub extern fn __mingw_str_wide_utf8(wptr: [*c]const wchar_t, mbptr: [*c][*c]u8, buflen: [*c]usize) c_int;
pub extern fn __mingw_str_utf8_wide(mbptr: [*c]const u8, wptr: [*c][*c]wchar_t, buflen: [*c]usize) c_int;
pub extern fn __mingw_str_free(ptr: ?*anyopaque) void;
pub extern fn _wspawnl(_Mode: c_int, _Filename: [*c]const wchar_t, _ArgList: [*c]const wchar_t, ...) isize;
pub extern fn _wspawnle(_Mode: c_int, _Filename: [*c]const wchar_t, _ArgList: [*c]const wchar_t, ...) isize;
pub extern fn _wspawnlp(_Mode: c_int, _Filename: [*c]const wchar_t, _ArgList: [*c]const wchar_t, ...) isize;
pub extern fn _wspawnlpe(_Mode: c_int, _Filename: [*c]const wchar_t, _ArgList: [*c]const wchar_t, ...) isize;
pub extern fn _wspawnv(_Mode: c_int, _Filename: [*c]const wchar_t, _ArgList: [*c]const [*c]const wchar_t) isize;
pub extern fn _wspawnve(_Mode: c_int, _Filename: [*c]const wchar_t, _ArgList: [*c]const [*c]const wchar_t, _Env: [*c]const [*c]const wchar_t) isize;
pub extern fn _wspawnvp(_Mode: c_int, _Filename: [*c]const wchar_t, _ArgList: [*c]const [*c]const wchar_t) isize;
pub extern fn _wspawnvpe(_Mode: c_int, _Filename: [*c]const wchar_t, _ArgList: [*c]const [*c]const wchar_t, _Env: [*c]const [*c]const wchar_t) isize;
pub extern fn _spawnv(_Mode: c_int, _Filename: [*c]const u8, _ArgList: [*c]const [*c]const u8) isize;
pub extern fn _spawnve(_Mode: c_int, _Filename: [*c]const u8, _ArgList: [*c]const [*c]const u8, _Env: [*c]const [*c]const u8) isize;
pub extern fn _spawnvp(_Mode: c_int, _Filename: [*c]const u8, _ArgList: [*c]const [*c]const u8) isize;
pub extern fn _spawnvpe(_Mode: c_int, _Filename: [*c]const u8, _ArgList: [*c]const [*c]const u8, _Env: [*c]const [*c]const u8) isize;
pub extern fn clearerr_s(_File: [*c]FILE) errno_t;
pub extern fn fread_s(_DstBuf: ?*anyopaque, _DstSize: usize, _ElementSize: usize, _Count: usize, _File: [*c]FILE) usize;
pub extern fn __stdio_common_vsprintf_s(_Options: c_ulonglong, _Str: [*c]u8, _Len: usize, _Format: [*c]const u8, _Locale: _locale_t, _ArgList: va_list) c_int;
pub extern fn __stdio_common_vsprintf_p(_Options: c_ulonglong, _Str: [*c]u8, _Len: usize, _Format: [*c]const u8, _Locale: _locale_t, _ArgList: va_list) c_int;
pub extern fn __stdio_common_vsnprintf_s(_Options: c_ulonglong, _Str: [*c]u8, _Len: usize, _MaxCount: usize, _Format: [*c]const u8, _Locale: _locale_t, _ArgList: va_list) c_int;
pub extern fn __stdio_common_vfprintf_s(_Options: c_ulonglong, _File: [*c]FILE, _Format: [*c]const u8, _Locale: _locale_t, _ArgList: va_list) c_int;
pub extern fn __stdio_common_vfprintf_p(_Options: c_ulonglong, _File: [*c]FILE, _Format: [*c]const u8, _Locale: _locale_t, _ArgList: va_list) c_int;
pub fn _vfscanf_s_l(arg__File: [*c]FILE, arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _File = arg__File;
    _ = &_File;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vfscanf(@as(c_ulonglong, 1), _File, _Format, _Locale, _ArgList);
}
pub fn vfscanf_s(arg__File: [*c]FILE, arg__Format: [*c]const u8, arg__ArgList: va_list) callconv(.c) c_int {
    var _File = arg__File;
    _ = &_File;
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfscanf_s_l(_File, _Format, null, _ArgList);
}
pub fn _vscanf_s_l(arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfscanf_s_l(__acrt_iob_func(@as(c_uint, @bitCast(@as(c_int, 0)))), _Format, _Locale, _ArgList);
}
pub fn vscanf_s(arg__Format: [*c]const u8, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfscanf_s_l(__acrt_iob_func(@as(c_uint, @bitCast(@as(c_int, 0)))), _Format, null, _ArgList);
}
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:60:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _fscanf_s_l(_File: [*c]FILE, _Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:70:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn fscanf_s(_File: [*c]FILE, _Format: [*c]const u8, ...) c_int;
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:80:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _scanf_s_l(_Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:90:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn scanf_s(_Format: [*c]const u8, ...) c_int;
pub fn _vfscanf_l(arg__File: [*c]FILE, arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _File = arg__File;
    _ = &_File;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vfscanf(@as(c_ulonglong, @bitCast(@as(c_longlong, @as(c_int, 0)))), _File, _Format, _Locale, _ArgList);
}
pub fn _vscanf_l(arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfscanf_l(__acrt_iob_func(@as(c_uint, @bitCast(@as(c_int, 0)))), _Format, _Locale, _ArgList);
}
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:110:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _fscanf_l(_File: [*c]FILE, _Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:119:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _scanf_l(_Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
pub fn _vsscanf_s_l(arg__Src: [*c]const u8, arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Src = arg__Src;
    _ = &_Src;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vsscanf(@as(c_ulonglong, 1), _Src, @as(usize, @bitCast(@as(c_longlong, -@as(c_int, 1)))), _Format, _Locale, _ArgList);
}
pub fn vsscanf_s(arg__Src: [*c]const u8, arg__Format: [*c]const u8, arg__ArgList: va_list) callconv(.c) c_int {
    var _Src = arg__Src;
    _ = &_Src;
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vsscanf_s_l(_Src, _Format, null, _ArgList);
}
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:137:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _sscanf_s_l(_Src: [*c]const u8, _Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:146:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn sscanf_s(_Src: [*c]const u8, _Format: [*c]const u8, ...) c_int;
pub fn _vsscanf_l(arg__Src: [*c]const u8, arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Src = arg__Src;
    _ = &_Src;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vsscanf(@as(c_ulonglong, @bitCast(@as(c_longlong, @as(c_int, 0)))), _Src, @as(usize, @bitCast(@as(c_longlong, -@as(c_int, 1)))), _Format, _Locale, _ArgList);
}
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:160:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _sscanf_l(_Src: [*c]const u8, _Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:171:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _snscanf_s_l(_Src: [*c]const u8, _MaxCount: usize, _Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:180:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _snscanf_s(_Src: [*c]const u8, _MaxCount: usize, _Format: [*c]const u8, ...) c_int;
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:191:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _snscanf_l(_Src: [*c]const u8, _MaxCount: usize, _Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
pub fn _vfprintf_s_l(arg__File: [*c]FILE, arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _File = arg__File;
    _ = &_File;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vfprintf_s(__local_stdio_printf_options().*, _File, _Format, _Locale, _ArgList);
}
pub fn vfprintf_s(arg__File: [*c]FILE, arg__Format: [*c]const u8, arg__ArgList: va_list) callconv(.c) c_int {
    var _File = arg__File;
    _ = &_File;
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfprintf_s_l(_File, _Format, null, _ArgList);
}
pub fn _vprintf_s_l(arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfprintf_s_l(__acrt_iob_func(@as(c_uint, @bitCast(@as(c_int, 1)))), _Format, _Locale, _ArgList);
}
pub fn vprintf_s(arg__Format: [*c]const u8, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfprintf_s_l(__acrt_iob_func(@as(c_uint, @bitCast(@as(c_int, 1)))), _Format, null, _ArgList);
}
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:218:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _fprintf_s_l(_File: [*c]FILE, _Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:227:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _printf_s_l(_Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:236:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn fprintf_s(_File: [*c]FILE, _Format: [*c]const u8, ...) c_int;
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:245:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn printf_s(_Format: [*c]const u8, ...) c_int;
pub fn _vsnprintf_c_l(arg__DstBuf: [*c]u8, arg__MaxCount: usize, arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _DstBuf = arg__DstBuf;
    _ = &_DstBuf;
    var _MaxCount = arg__MaxCount;
    _ = &_MaxCount;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vsprintf(__local_stdio_printf_options().*, _DstBuf, _MaxCount, _Format, _Locale, _ArgList);
}
pub fn _vsnprintf_c(arg__DstBuf: [*c]u8, arg__MaxCount: usize, arg__Format: [*c]const u8, arg__ArgList: va_list) callconv(.c) c_int {
    var _DstBuf = arg__DstBuf;
    _ = &_DstBuf;
    var _MaxCount = arg__MaxCount;
    _ = &_MaxCount;
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vsnprintf_c_l(_DstBuf, _MaxCount, _Format, null, _ArgList);
}
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:263:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _snprintf_c_l(_DstBuf: [*c]u8, _MaxCount: usize, _Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:272:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _snprintf_c(_DstBuf: [*c]u8, _MaxCount: usize, _Format: [*c]const u8, ...) c_int;
pub fn _vsnprintf_s_l(arg__DstBuf: [*c]u8, arg__DstSize: usize, arg__MaxCount: usize, arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _DstBuf = arg__DstBuf;
    _ = &_DstBuf;
    var _DstSize = arg__DstSize;
    _ = &_DstSize;
    var _MaxCount = arg__MaxCount;
    _ = &_MaxCount;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vsnprintf_s(__local_stdio_printf_options().*, _DstBuf, _DstSize, _MaxCount, _Format, _Locale, _ArgList);
}
pub fn vsnprintf_s(arg__DstBuf: [*c]u8, arg__DstSize: usize, arg__MaxCount: usize, arg__Format: [*c]const u8, arg__ArgList: va_list) callconv(.c) c_int {
    var _DstBuf = arg__DstBuf;
    _ = &_DstBuf;
    var _DstSize = arg__DstSize;
    _ = &_DstSize;
    var _MaxCount = arg__MaxCount;
    _ = &_MaxCount;
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vsnprintf_s_l(_DstBuf, _DstSize, _MaxCount, _Format, null, _ArgList);
}
pub fn _vsnprintf_s(arg__DstBuf: [*c]u8, arg__DstSize: usize, arg__MaxCount: usize, arg__Format: [*c]const u8, arg__ArgList: va_list) callconv(.c) c_int {
    var _DstBuf = arg__DstBuf;
    _ = &_DstBuf;
    var _DstSize = arg__DstSize;
    _ = &_DstSize;
    var _MaxCount = arg__MaxCount;
    _ = &_MaxCount;
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vsnprintf_s_l(_DstBuf, _DstSize, _MaxCount, _Format, null, _ArgList);
}
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:294:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _snprintf_s_l(_DstBuf: [*c]u8, _DstSize: usize, _MaxCount: usize, _Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:303:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _snprintf_s(_DstBuf: [*c]u8, _DstSize: usize, _MaxCount: usize, _Format: [*c]const u8, ...) c_int;
pub fn _vsprintf_s_l(arg__DstBuf: [*c]u8, arg__DstSize: usize, arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _DstBuf = arg__DstBuf;
    _ = &_DstBuf;
    var _DstSize = arg__DstSize;
    _ = &_DstSize;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vsprintf_s(__local_stdio_printf_options().*, _DstBuf, _DstSize, _Format, _Locale, _ArgList);
}
pub fn vsprintf_s(arg__DstBuf: [*c]u8, arg__Size: usize, arg__Format: [*c]const u8, arg__ArgList: va_list) callconv(.c) c_int {
    var _DstBuf = arg__DstBuf;
    _ = &_DstBuf;
    var _Size = arg__Size;
    _ = &_Size;
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vsprintf_s_l(_DstBuf, _Size, _Format, null, _ArgList);
}
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:321:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _sprintf_s_l(_DstBuf: [*c]u8, _DstSize: usize, _Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:330:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn sprintf_s(_DstBuf: [*c]u8, _DstSize: usize, _Format: [*c]const u8, ...) c_int;
pub fn _vfprintf_p_l(arg__File: [*c]FILE, arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _File = arg__File;
    _ = &_File;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vfprintf_p(__local_stdio_printf_options().*, _File, _Format, _Locale, _ArgList);
}
pub fn _vfprintf_p(arg__File: [*c]FILE, arg__Format: [*c]const u8, arg__ArgList: va_list) callconv(.c) c_int {
    var _File = arg__File;
    _ = &_File;
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfprintf_p_l(_File, _Format, null, _ArgList);
}
pub fn _vprintf_p_l(arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfprintf_p_l(__acrt_iob_func(@as(c_uint, @bitCast(@as(c_int, 1)))), _Format, _Locale, _ArgList);
}
pub fn _vprintf_p(arg__Format: [*c]const u8, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfprintf_p_l(__acrt_iob_func(@as(c_uint, @bitCast(@as(c_int, 1)))), _Format, null, _ArgList);
}
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:356:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _fprintf_p_l(_File: [*c]FILE, _Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:365:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _fprintf_p(_File: [*c]FILE, _Format: [*c]const u8, ...) c_int;
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:374:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _printf_p_l(_Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:383:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _printf_p(_Format: [*c]const u8, ...) c_int;
pub fn _vsprintf_p_l(arg__DstBuf: [*c]u8, arg__MaxCount: usize, arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _DstBuf = arg__DstBuf;
    _ = &_DstBuf;
    var _MaxCount = arg__MaxCount;
    _ = &_MaxCount;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vsprintf_p(__local_stdio_printf_options().*, _DstBuf, _MaxCount, _Format, _Locale, _ArgList);
}
pub fn _vsprintf_p(arg__Dst: [*c]u8, arg__MaxCount: usize, arg__Format: [*c]const u8, arg__ArgList: va_list) callconv(.c) c_int {
    var _Dst = arg__Dst;
    _ = &_Dst;
    var _MaxCount = arg__MaxCount;
    _ = &_MaxCount;
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vsprintf_p_l(_Dst, _MaxCount, _Format, null, _ArgList);
}
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:401:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _sprintf_p_l(_DstBuf: [*c]u8, _MaxCount: usize, _Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:410:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _sprintf_p(_Dst: [*c]u8, _MaxCount: usize, _Format: [*c]const u8, ...) c_int;
pub fn _vscprintf_p_l(arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vsprintf_p(@as(c_ulonglong, 2), null, @as(usize, @bitCast(@as(c_longlong, @as(c_int, 0)))), _Format, _Locale, _ArgList);
}
pub fn _vscprintf_p(arg__Format: [*c]const u8, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vscprintf_p_l(_Format, null, _ArgList);
}
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:428:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _scprintf_p_l(_Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:437:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _scprintf_p(_Format: [*c]const u8, ...) c_int;
pub fn _vfprintf_l(arg__File: [*c]FILE, arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _File = arg__File;
    _ = &_File;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vfprintf(__local_stdio_printf_options().*, _File, _Format, _Locale, _ArgList);
}
pub fn _vprintf_l(arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfprintf_l(__acrt_iob_func(@as(c_uint, @bitCast(@as(c_int, 1)))), _Format, _Locale, _ArgList);
}
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:455:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _fprintf_l(_File: [*c]FILE, _Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:464:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _printf_l(_Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
pub fn _vsnprintf_l(arg__DstBuf: [*c]u8, arg__MaxCount: usize, arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _DstBuf = arg__DstBuf;
    _ = &_DstBuf;
    var _MaxCount = arg__MaxCount;
    _ = &_MaxCount;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vsprintf(@as(c_ulonglong, 1), _DstBuf, _MaxCount, _Format, _Locale, _ArgList);
}
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:478:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _snprintf_l(_DstBuf: [*c]u8, _MaxCount: usize, _Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
pub fn _vsprintf_l(arg__DstBuf: [*c]u8, arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _DstBuf = arg__DstBuf;
    _ = &_DstBuf;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vsnprintf_l(_DstBuf, @as(usize, @bitCast(@as(c_longlong, -@as(c_int, 1)))), _Format, _Locale, _ArgList);
}
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:491:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _sprintf_l(_DstBuf: [*c]u8, _Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
pub fn _vscprintf_l(arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vsprintf(@as(c_ulonglong, 2), null, @as(usize, @bitCast(@as(c_longlong, @as(c_int, 0)))), _Format, _Locale, _ArgList);
}
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:505:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _scprintf_l(_Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
pub extern fn fopen_s(_File: [*c][*c]FILE, _Filename: [*c]const u8, _Mode: [*c]const u8) errno_t;
pub extern fn freopen_s(_File: [*c][*c]FILE, _Filename: [*c]const u8, _Mode: [*c]const u8, _Stream: [*c]FILE) errno_t;
pub extern fn gets_s([*c]u8, rsize_t) [*c]u8;
pub extern fn tmpfile_s(_File: [*c][*c]FILE) errno_t;
pub extern fn tmpnam_s([*c]u8, rsize_t) errno_t;
pub extern fn _getws_s(_Str: [*c]wchar_t, _SizeInWords: usize) [*c]wchar_t;
pub extern fn __stdio_common_vswprintf_s(_Options: c_ulonglong, _Str: [*c]wchar_t, _Len: usize, _Format: [*c]const wchar_t, _Locale: _locale_t, _ArgList: va_list) c_int;
pub extern fn __stdio_common_vsnwprintf_s(_Options: c_ulonglong, _Str: [*c]wchar_t, _Len: usize, _MaxCount: usize, _Format: [*c]const wchar_t, _Locale: _locale_t, _ArgList: va_list) c_int;
pub extern fn __stdio_common_vfwprintf_s(_Options: c_ulonglong, _File: [*c]FILE, _Format: [*c]const wchar_t, _Locale: _locale_t, _ArgList: va_list) c_int;
pub fn _vfwscanf_s_l(arg__File: [*c]FILE, arg__Format: [*c]const wchar_t, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _File = arg__File;
    _ = &_File;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vfwscanf(__local_stdio_scanf_options().* | @as(c_ulonglong, 1), _File, _Format, _Locale, _ArgList);
}
pub fn vfwscanf_s(arg__File: [*c]FILE, arg__Format: [*c]const wchar_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _File = arg__File;
    _ = &_File;
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfwscanf_s_l(_File, _Format, null, _ArgList);
}
pub fn _vwscanf_s_l(arg__Format: [*c]const wchar_t, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfwscanf_s_l(__acrt_iob_func(@as(c_uint, @bitCast(@as(c_int, 0)))), _Format, _Locale, _ArgList);
}
pub fn vwscanf_s(arg__Format: [*c]const wchar_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfwscanf_s_l(__acrt_iob_func(@as(c_uint, @bitCast(@as(c_int, 0)))), _Format, null, _ArgList);
}
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:631:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _fwscanf_s_l(_File: [*c]FILE, _Format: [*c]const wchar_t, _Locale: _locale_t, ...) c_int;
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:641:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn fwscanf_s(_File: [*c]FILE, _Format: [*c]const wchar_t, ...) c_int;
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:651:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _wscanf_s_l(_Format: [*c]const wchar_t, _Locale: _locale_t, ...) c_int;
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:661:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn wscanf_s(_Format: [*c]const wchar_t, ...) c_int;
pub fn _vswscanf_s_l(arg__Src: [*c]const wchar_t, arg__Format: [*c]const wchar_t, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Src = arg__Src;
    _ = &_Src;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vswscanf(__local_stdio_scanf_options().* | @as(c_ulonglong, 1), _Src, @as(usize, @bitCast(@as(c_longlong, -@as(c_int, 1)))), _Format, _Locale, _ArgList);
}
pub fn vswscanf_s(arg__Src: [*c]const wchar_t, arg__Format: [*c]const wchar_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Src = arg__Src;
    _ = &_Src;
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vswscanf_s_l(_Src, _Format, null, _ArgList);
}
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:681:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _swscanf_s_l(_Src: [*c]const wchar_t, _Format: [*c]const wchar_t, _Locale: _locale_t, ...) c_int;
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:690:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn swscanf_s(_Src: [*c]const wchar_t, _Format: [*c]const wchar_t, ...) c_int;
pub fn _vsnwscanf_s_l(arg__Src: [*c]const wchar_t, arg__MaxCount: usize, arg__Format: [*c]const wchar_t, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Src = arg__Src;
    _ = &_Src;
    var _MaxCount = arg__MaxCount;
    _ = &_MaxCount;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vswscanf(__local_stdio_scanf_options().* | @as(c_ulonglong, 1), _Src, _MaxCount, _Format, _Locale, _ArgList);
}
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:704:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _snwscanf_s_l(_Src: [*c]const wchar_t, _MaxCount: usize, _Format: [*c]const wchar_t, _Locale: _locale_t, ...) c_int;
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:713:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _snwscanf_s(_Src: [*c]const wchar_t, _MaxCount: usize, _Format: [*c]const wchar_t, ...) c_int;
pub fn _vfwprintf_s_l(arg__File: [*c]FILE, arg__Format: [*c]const wchar_t, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _File = arg__File;
    _ = &_File;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vfwprintf_s(__local_stdio_printf_options().*, _File, _Format, _Locale, _ArgList);
}
pub fn _vwprintf_s_l(arg__Format: [*c]const wchar_t, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfwprintf_s_l(__acrt_iob_func(@as(c_uint, @bitCast(@as(c_int, 1)))), _Format, _Locale, _ArgList);
}
pub fn vfwprintf_s(arg__File: [*c]FILE, arg__Format: [*c]const wchar_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _File = arg__File;
    _ = &_File;
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfwprintf_s_l(_File, _Format, null, _ArgList);
}
pub fn vwprintf_s(arg__Format: [*c]const wchar_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfwprintf_s_l(__acrt_iob_func(@as(c_uint, @bitCast(@as(c_int, 1)))), _Format, null, _ArgList);
}
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:739:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _fwprintf_s_l(_File: [*c]FILE, _Format: [*c]const wchar_t, _Locale: _locale_t, ...) c_int;
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:748:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _wprintf_s_l(_Format: [*c]const wchar_t, _Locale: _locale_t, ...) c_int;
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:757:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn fwprintf_s(_File: [*c]FILE, _Format: [*c]const wchar_t, ...) c_int;
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:766:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn wprintf_s(_Format: [*c]const wchar_t, ...) c_int;
pub fn _vswprintf_s_l(arg__DstBuf: [*c]wchar_t, arg__DstSize: usize, arg__Format: [*c]const wchar_t, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _DstBuf = arg__DstBuf;
    _ = &_DstBuf;
    var _DstSize = arg__DstSize;
    _ = &_DstSize;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vswprintf_s(__local_stdio_printf_options().*, _DstBuf, _DstSize, _Format, _Locale, _ArgList);
}
pub fn vswprintf_s(arg__DstBuf: [*c]wchar_t, arg__DstSize: usize, arg__Format: [*c]const wchar_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _DstBuf = arg__DstBuf;
    _ = &_DstBuf;
    var _DstSize = arg__DstSize;
    _ = &_DstSize;
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vswprintf_s_l(_DstBuf, _DstSize, _Format, null, _ArgList);
}
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:784:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _swprintf_s_l(_DstBuf: [*c]wchar_t, _DstSize: usize, _Format: [*c]const wchar_t, _Locale: _locale_t, ...) c_int;
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:793:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn swprintf_s(_DstBuf: [*c]wchar_t, _DstSize: usize, _Format: [*c]const wchar_t, ...) c_int;
pub fn _vsnwprintf_s_l(arg__DstBuf: [*c]wchar_t, arg__DstSize: usize, arg__MaxCount: usize, arg__Format: [*c]const wchar_t, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _DstBuf = arg__DstBuf;
    _ = &_DstBuf;
    var _DstSize = arg__DstSize;
    _ = &_DstSize;
    var _MaxCount = arg__MaxCount;
    _ = &_MaxCount;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vsnwprintf_s(__local_stdio_printf_options().*, _DstBuf, _DstSize, _MaxCount, _Format, _Locale, _ArgList);
}
pub fn _vsnwprintf_s(arg__DstBuf: [*c]wchar_t, arg__DstSize: usize, arg__MaxCount: usize, arg__Format: [*c]const wchar_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _DstBuf = arg__DstBuf;
    _ = &_DstBuf;
    var _DstSize = arg__DstSize;
    _ = &_DstSize;
    var _MaxCount = arg__MaxCount;
    _ = &_MaxCount;
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vsnwprintf_s_l(_DstBuf, _DstSize, _MaxCount, _Format, null, _ArgList);
}
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:811:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _snwprintf_s_l(_DstBuf: [*c]wchar_t, _DstSize: usize, _MaxCount: usize, _Format: [*c]const wchar_t, _Locale: _locale_t, ...) c_int;
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:820:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _snwprintf_s(_DstBuf: [*c]wchar_t, _DstSize: usize, _MaxCount: usize, _Format: [*c]const wchar_t, ...) c_int;
pub extern fn _wfopen_s(_File: [*c][*c]FILE, _Filename: [*c]const wchar_t, _Mode: [*c]const wchar_t) errno_t;
pub extern fn _wfreopen_s(_File: [*c][*c]FILE, _Filename: [*c]const wchar_t, _Mode: [*c]const wchar_t, _OldFile: [*c]FILE) errno_t;
pub extern fn _wtmpnam_s(_DstBuf: [*c]wchar_t, _SizeInWords: usize) errno_t;
pub extern fn _fread_nolock_s(_DstBuf: ?*anyopaque, _DstSize: usize, _ElementSize: usize, _Count: usize, _File: [*c]FILE) usize;
pub const xmlChar = u8;
pub extern fn xmlStrdup(cur: [*c]const xmlChar) [*c]xmlChar;
pub extern fn xmlStrndup(cur: [*c]const xmlChar, len: c_int) [*c]xmlChar;
pub extern fn xmlCharStrndup(cur: [*c]const u8, len: c_int) [*c]xmlChar;
pub extern fn xmlCharStrdup(cur: [*c]const u8) [*c]xmlChar;
pub extern fn xmlStrsub(str: [*c]const xmlChar, start: c_int, len: c_int) [*c]xmlChar;
pub extern fn xmlStrchr(str: [*c]const xmlChar, val: xmlChar) [*c]const xmlChar;
pub extern fn xmlStrstr(str: [*c]const xmlChar, val: [*c]const xmlChar) [*c]const xmlChar;
pub extern fn xmlStrcasestr(str: [*c]const xmlChar, val: [*c]const xmlChar) [*c]const xmlChar;
pub extern fn xmlStrcmp(str1: [*c]const xmlChar, str2: [*c]const xmlChar) c_int;
pub extern fn xmlStrncmp(str1: [*c]const xmlChar, str2: [*c]const xmlChar, len: c_int) c_int;
pub extern fn xmlStrcasecmp(str1: [*c]const xmlChar, str2: [*c]const xmlChar) c_int;
pub extern fn xmlStrncasecmp(str1: [*c]const xmlChar, str2: [*c]const xmlChar, len: c_int) c_int;
pub extern fn xmlStrEqual(str1: [*c]const xmlChar, str2: [*c]const xmlChar) c_int;
pub extern fn xmlStrQEqual(pref: [*c]const xmlChar, name: [*c]const xmlChar, str: [*c]const xmlChar) c_int;
pub extern fn xmlStrlen(str: [*c]const xmlChar) c_int;
pub extern fn xmlStrcat(cur: [*c]xmlChar, add: [*c]const xmlChar) [*c]xmlChar;
pub extern fn xmlStrncat(cur: [*c]xmlChar, add: [*c]const xmlChar, len: c_int) [*c]xmlChar;
pub extern fn xmlStrncatNew(str1: [*c]const xmlChar, str2: [*c]const xmlChar, len: c_int) [*c]xmlChar;
pub extern fn xmlStrPrintf(buf: [*c]xmlChar, len: c_int, msg: [*c]const u8, ...) c_int;
pub extern fn xmlStrVPrintf(buf: [*c]xmlChar, len: c_int, msg: [*c]const u8, ap: va_list) c_int;
pub extern fn xmlGetUTF8Char(utf: [*c]const u8, len: [*c]c_int) c_int;
pub extern fn xmlCheckUTF8(utf: [*c]const u8) c_int;
pub extern fn xmlUTF8Strsize(utf: [*c]const xmlChar, len: c_int) c_int;
pub extern fn xmlUTF8Strndup(utf: [*c]const xmlChar, len: c_int) [*c]xmlChar;
pub extern fn xmlUTF8Strpos(utf: [*c]const xmlChar, pos: c_int) [*c]const xmlChar;
pub extern fn xmlUTF8Strloc(utf: [*c]const xmlChar, utfchar: [*c]const xmlChar) c_int;
pub extern fn xmlUTF8Strsub(utf: [*c]const xmlChar, start: c_int, len: c_int) [*c]xmlChar;
pub extern fn xmlUTF8Strlen(utf: [*c]const xmlChar) c_int;
pub extern fn xmlUTF8Size(utf: [*c]const xmlChar) c_int;
pub extern fn xmlUTF8Charcmp(utf1: [*c]const xmlChar, utf2: [*c]const xmlChar) c_int;
pub const xmlInputReadCallback = ?*const fn (?*anyopaque, [*c]u8, c_int) callconv(.c) c_int;
pub const xmlInputCloseCallback = ?*const fn (?*anyopaque) callconv(.c) c_int;
pub const xmlCharEncodingInputFunc = ?*const fn ([*c]u8, [*c]c_int, [*c]const u8, [*c]c_int) callconv(.c) c_int;
pub const xmlCharEncodingOutputFunc = ?*const fn ([*c]u8, [*c]c_int, [*c]const u8, [*c]c_int) callconv(.c) c_int;
pub const struct__xmlCharEncodingHandler = extern struct {
    name: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    input: xmlCharEncodingInputFunc = @import("std").mem.zeroes(xmlCharEncodingInputFunc),
    output: xmlCharEncodingOutputFunc = @import("std").mem.zeroes(xmlCharEncodingOutputFunc),
};
pub const xmlCharEncodingHandler = struct__xmlCharEncodingHandler;
pub const xmlCharEncodingHandlerPtr = [*c]xmlCharEncodingHandler;
pub const struct__xmlBuf = opaque {};
pub const xmlBuf = struct__xmlBuf;
pub const xmlBufPtr = ?*xmlBuf;
pub const struct__xmlParserInputBuffer = extern struct {
    context: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    readcallback: xmlInputReadCallback = @import("std").mem.zeroes(xmlInputReadCallback),
    closecallback: xmlInputCloseCallback = @import("std").mem.zeroes(xmlInputCloseCallback),
    encoder: xmlCharEncodingHandlerPtr = @import("std").mem.zeroes(xmlCharEncodingHandlerPtr),
    buffer: xmlBufPtr = @import("std").mem.zeroes(xmlBufPtr),
    raw: xmlBufPtr = @import("std").mem.zeroes(xmlBufPtr),
    compressed: c_int = @import("std").mem.zeroes(c_int),
    @"error": c_int = @import("std").mem.zeroes(c_int),
    rawconsumed: c_ulong = @import("std").mem.zeroes(c_ulong),
};
pub const xmlParserInputBuffer = struct__xmlParserInputBuffer;
pub const xmlParserInputBufferPtr = [*c]xmlParserInputBuffer;
pub const struct__xmlOutputBuffer = opaque {};
pub const xmlOutputBuffer = struct__xmlOutputBuffer;
pub const xmlOutputBufferPtr = ?*xmlOutputBuffer;
pub const xmlParserInputDeallocate = ?*const fn ([*c]xmlChar) callconv(.c) void;
pub const struct__xmlDtd = extern struct {
    _private: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    type: xmlElementType = @import("std").mem.zeroes(xmlElementType),
    name: [*c]const xmlChar = @import("std").mem.zeroes([*c]const xmlChar),
    children: [*c]struct__xmlNode = @import("std").mem.zeroes([*c]struct__xmlNode),
    last: [*c]struct__xmlNode = @import("std").mem.zeroes([*c]struct__xmlNode),
    parent: [*c]struct__xmlDoc = @import("std").mem.zeroes([*c]struct__xmlDoc),
    next: [*c]struct__xmlNode = @import("std").mem.zeroes([*c]struct__xmlNode),
    prev: [*c]struct__xmlNode = @import("std").mem.zeroes([*c]struct__xmlNode),
    doc: [*c]struct__xmlDoc = @import("std").mem.zeroes([*c]struct__xmlDoc),
    notations: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    elements: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    attributes: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    entities: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    ExternalID: [*c]const xmlChar = @import("std").mem.zeroes([*c]const xmlChar),
    SystemID: [*c]const xmlChar = @import("std").mem.zeroes([*c]const xmlChar),
    pentities: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
};
pub const xmlNsType = xmlElementType;
pub const struct__xmlNs = extern struct {
    next: [*c]struct__xmlNs = @import("std").mem.zeroes([*c]struct__xmlNs),
    type: xmlNsType = @import("std").mem.zeroes(xmlNsType),
    href: [*c]const xmlChar = @import("std").mem.zeroes([*c]const xmlChar),
    prefix: [*c]const xmlChar = @import("std").mem.zeroes([*c]const xmlChar),
    _private: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    context: [*c]struct__xmlDoc = @import("std").mem.zeroes([*c]struct__xmlDoc),
};
pub const struct__xmlDict_1 = opaque {};
pub const struct__xmlDoc = extern struct {
    _private: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    type: xmlElementType = @import("std").mem.zeroes(xmlElementType),
    name: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    children: [*c]struct__xmlNode = @import("std").mem.zeroes([*c]struct__xmlNode),
    last: [*c]struct__xmlNode = @import("std").mem.zeroes([*c]struct__xmlNode),
    parent: [*c]struct__xmlNode = @import("std").mem.zeroes([*c]struct__xmlNode),
    next: [*c]struct__xmlNode = @import("std").mem.zeroes([*c]struct__xmlNode),
    prev: [*c]struct__xmlNode = @import("std").mem.zeroes([*c]struct__xmlNode),
    doc: [*c]struct__xmlDoc = @import("std").mem.zeroes([*c]struct__xmlDoc),
    compression: c_int = @import("std").mem.zeroes(c_int),
    standalone: c_int = @import("std").mem.zeroes(c_int),
    intSubset: [*c]struct__xmlDtd = @import("std").mem.zeroes([*c]struct__xmlDtd),
    extSubset: [*c]struct__xmlDtd = @import("std").mem.zeroes([*c]struct__xmlDtd),
    oldNs: [*c]struct__xmlNs = @import("std").mem.zeroes([*c]struct__xmlNs),
    version: [*c]const xmlChar = @import("std").mem.zeroes([*c]const xmlChar),
    encoding: [*c]const xmlChar = @import("std").mem.zeroes([*c]const xmlChar),
    ids: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    refs: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    URL: [*c]const xmlChar = @import("std").mem.zeroes([*c]const xmlChar),
    charset: c_int = @import("std").mem.zeroes(c_int),
    dict: ?*struct__xmlDict_1 = @import("std").mem.zeroes(?*struct__xmlDict_1),
    psvi: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    parseFlags: c_int = @import("std").mem.zeroes(c_int),
    properties: c_int = @import("std").mem.zeroes(c_int),
};
pub const xmlNs = struct__xmlNs;
pub const struct__xmlAttr = extern struct {
    _private: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    type: xmlElementType = @import("std").mem.zeroes(xmlElementType),
    name: [*c]const xmlChar = @import("std").mem.zeroes([*c]const xmlChar),
    children: [*c]struct__xmlNode = @import("std").mem.zeroes([*c]struct__xmlNode),
    last: [*c]struct__xmlNode = @import("std").mem.zeroes([*c]struct__xmlNode),
    parent: [*c]struct__xmlNode = @import("std").mem.zeroes([*c]struct__xmlNode),
    next: [*c]struct__xmlAttr = @import("std").mem.zeroes([*c]struct__xmlAttr),
    prev: [*c]struct__xmlAttr = @import("std").mem.zeroes([*c]struct__xmlAttr),
    doc: [*c]struct__xmlDoc = @import("std").mem.zeroes([*c]struct__xmlDoc),
    ns: [*c]xmlNs = @import("std").mem.zeroes([*c]xmlNs),
    atype: xmlAttributeType = @import("std").mem.zeroes(xmlAttributeType),
    psvi: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
};
pub const struct__xmlNode = extern struct {
    _private: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    type: xmlElementType = @import("std").mem.zeroes(xmlElementType),
    name: [*c]const xmlChar = @import("std").mem.zeroes([*c]const xmlChar),
    children: [*c]struct__xmlNode = @import("std").mem.zeroes([*c]struct__xmlNode),
    last: [*c]struct__xmlNode = @import("std").mem.zeroes([*c]struct__xmlNode),
    parent: [*c]struct__xmlNode = @import("std").mem.zeroes([*c]struct__xmlNode),
    next: [*c]struct__xmlNode = @import("std").mem.zeroes([*c]struct__xmlNode),
    prev: [*c]struct__xmlNode = @import("std").mem.zeroes([*c]struct__xmlNode),
    doc: [*c]struct__xmlDoc = @import("std").mem.zeroes([*c]struct__xmlDoc),
    ns: [*c]xmlNs = @import("std").mem.zeroes([*c]xmlNs),
    content: [*c]xmlChar = @import("std").mem.zeroes([*c]xmlChar),
    properties: [*c]struct__xmlAttr = @import("std").mem.zeroes([*c]struct__xmlAttr),
    nsDef: [*c]xmlNs = @import("std").mem.zeroes([*c]xmlNs),
    psvi: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    line: c_ushort = @import("std").mem.zeroes(c_ushort),
    extra: c_ushort = @import("std").mem.zeroes(c_ushort),
};
pub const struct__xmlEntity = extern struct {
    _private: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    type: xmlElementType = @import("std").mem.zeroes(xmlElementType),
    name: [*c]const xmlChar = @import("std").mem.zeroes([*c]const xmlChar),
    children: [*c]struct__xmlNode = @import("std").mem.zeroes([*c]struct__xmlNode),
    last: [*c]struct__xmlNode = @import("std").mem.zeroes([*c]struct__xmlNode),
    parent: [*c]struct__xmlDtd = @import("std").mem.zeroes([*c]struct__xmlDtd),
    next: [*c]struct__xmlNode = @import("std").mem.zeroes([*c]struct__xmlNode),
    prev: [*c]struct__xmlNode = @import("std").mem.zeroes([*c]struct__xmlNode),
    doc: [*c]struct__xmlDoc = @import("std").mem.zeroes([*c]struct__xmlDoc),
    orig: [*c]xmlChar = @import("std").mem.zeroes([*c]xmlChar),
    content: [*c]xmlChar = @import("std").mem.zeroes([*c]xmlChar),
    length: c_int = @import("std").mem.zeroes(c_int),
    etype: xmlEntityType = @import("std").mem.zeroes(xmlEntityType),
    ExternalID: [*c]const xmlChar = @import("std").mem.zeroes([*c]const xmlChar),
    SystemID: [*c]const xmlChar = @import("std").mem.zeroes([*c]const xmlChar),
    nexte: [*c]struct__xmlEntity = @import("std").mem.zeroes([*c]struct__xmlEntity),
    URI: [*c]const xmlChar = @import("std").mem.zeroes([*c]const xmlChar),
    owner: c_int = @import("std").mem.zeroes(c_int),
    flags: c_int = @import("std").mem.zeroes(c_int),
    expandedSize: c_ulong = @import("std").mem.zeroes(c_ulong),
};
pub const xmlEntity = struct__xmlEntity;
pub const xmlEntityPtr = [*c]xmlEntity;
pub const struct__xmlParserInput = extern struct {
    buf: xmlParserInputBufferPtr = @import("std").mem.zeroes(xmlParserInputBufferPtr),
    filename: [*c]const u8 = @import("std").mem.zeroes([*c]const u8),
    directory: [*c]const u8 = @import("std").mem.zeroes([*c]const u8),
    base: [*c]const xmlChar = @import("std").mem.zeroes([*c]const xmlChar),
    cur: [*c]const xmlChar = @import("std").mem.zeroes([*c]const xmlChar),
    end: [*c]const xmlChar = @import("std").mem.zeroes([*c]const xmlChar),
    length: c_int = @import("std").mem.zeroes(c_int),
    line: c_int = @import("std").mem.zeroes(c_int),
    col: c_int = @import("std").mem.zeroes(c_int),
    consumed: c_ulong = @import("std").mem.zeroes(c_ulong),
    free: xmlParserInputDeallocate = @import("std").mem.zeroes(xmlParserInputDeallocate),
    encoding: [*c]const xmlChar = @import("std").mem.zeroes([*c]const xmlChar),
    version: [*c]const xmlChar = @import("std").mem.zeroes([*c]const xmlChar),
    standalone: c_int = @import("std").mem.zeroes(c_int),
    id: c_int = @import("std").mem.zeroes(c_int),
    parentConsumed: c_ulong = @import("std").mem.zeroes(c_ulong),
    entity: xmlEntityPtr = @import("std").mem.zeroes(xmlEntityPtr),
};
pub const xmlParserInput = struct__xmlParserInput;
pub const xmlParserInputPtr = [*c]xmlParserInput;
pub const internalSubsetSAXFunc = ?*const fn (?*anyopaque, [*c]const xmlChar, [*c]const xmlChar, [*c]const xmlChar) callconv(.c) void;
pub const isStandaloneSAXFunc = ?*const fn (?*anyopaque) callconv(.c) c_int;
pub const hasInternalSubsetSAXFunc = ?*const fn (?*anyopaque) callconv(.c) c_int;
pub const hasExternalSubsetSAXFunc = ?*const fn (?*anyopaque) callconv(.c) c_int;
pub const resolveEntitySAXFunc = ?*const fn (?*anyopaque, [*c]const xmlChar, [*c]const xmlChar) callconv(.c) xmlParserInputPtr;
pub const getEntitySAXFunc = ?*const fn (?*anyopaque, [*c]const xmlChar) callconv(.c) xmlEntityPtr;
pub const entityDeclSAXFunc = ?*const fn (?*anyopaque, [*c]const xmlChar, c_int, [*c]const xmlChar, [*c]const xmlChar, [*c]xmlChar) callconv(.c) void;
pub const notationDeclSAXFunc = ?*const fn (?*anyopaque, [*c]const xmlChar, [*c]const xmlChar, [*c]const xmlChar) callconv(.c) void;
pub const struct__xmlEnumeration = extern struct {
    next: [*c]struct__xmlEnumeration = @import("std").mem.zeroes([*c]struct__xmlEnumeration),
    name: [*c]const xmlChar = @import("std").mem.zeroes([*c]const xmlChar),
};
pub const xmlEnumeration = struct__xmlEnumeration;
pub const xmlEnumerationPtr = [*c]xmlEnumeration;
pub const attributeDeclSAXFunc = ?*const fn (?*anyopaque, [*c]const xmlChar, [*c]const xmlChar, c_int, c_int, [*c]const xmlChar, xmlEnumerationPtr) callconv(.c) void;
pub const struct__xmlElementContent = extern struct {
    type: xmlElementContentType = @import("std").mem.zeroes(xmlElementContentType),
    ocur: xmlElementContentOccur = @import("std").mem.zeroes(xmlElementContentOccur),
    name: [*c]const xmlChar = @import("std").mem.zeroes([*c]const xmlChar),
    c1: [*c]struct__xmlElementContent = @import("std").mem.zeroes([*c]struct__xmlElementContent),
    c2: [*c]struct__xmlElementContent = @import("std").mem.zeroes([*c]struct__xmlElementContent),
    parent: [*c]struct__xmlElementContent = @import("std").mem.zeroes([*c]struct__xmlElementContent),
    prefix: [*c]const xmlChar = @import("std").mem.zeroes([*c]const xmlChar),
};
pub const xmlElementContent = struct__xmlElementContent;
pub const xmlElementContentPtr = [*c]xmlElementContent;
pub const elementDeclSAXFunc = ?*const fn (?*anyopaque, [*c]const xmlChar, c_int, xmlElementContentPtr) callconv(.c) void;
pub const unparsedEntityDeclSAXFunc = ?*const fn (?*anyopaque, [*c]const xmlChar, [*c]const xmlChar, [*c]const xmlChar, [*c]const xmlChar) callconv(.c) void;
pub const struct__xmlSAXLocator = extern struct {
    getPublicId: ?*const fn (?*anyopaque) callconv(.c) [*c]const xmlChar = @import("std").mem.zeroes(?*const fn (?*anyopaque) callconv(.c) [*c]const xmlChar),
    getSystemId: ?*const fn (?*anyopaque) callconv(.c) [*c]const xmlChar = @import("std").mem.zeroes(?*const fn (?*anyopaque) callconv(.c) [*c]const xmlChar),
    getLineNumber: ?*const fn (?*anyopaque) callconv(.c) c_int = @import("std").mem.zeroes(?*const fn (?*anyopaque) callconv(.c) c_int),
    getColumnNumber: ?*const fn (?*anyopaque) callconv(.c) c_int = @import("std").mem.zeroes(?*const fn (?*anyopaque) callconv(.c) c_int),
};
pub const xmlSAXLocator = struct__xmlSAXLocator;
pub const xmlSAXLocatorPtr = [*c]xmlSAXLocator;
pub const setDocumentLocatorSAXFunc = ?*const fn (?*anyopaque, xmlSAXLocatorPtr) callconv(.c) void;
pub const startDocumentSAXFunc = ?*const fn (?*anyopaque) callconv(.c) void;
pub const endDocumentSAXFunc = ?*const fn (?*anyopaque) callconv(.c) void;
pub const startElementSAXFunc = ?*const fn (?*anyopaque, [*c]const xmlChar, [*c][*c]const xmlChar) callconv(.c) void;
pub const endElementSAXFunc = ?*const fn (?*anyopaque, [*c]const xmlChar) callconv(.c) void;
pub const referenceSAXFunc = ?*const fn (?*anyopaque, [*c]const xmlChar) callconv(.c) void;
pub const charactersSAXFunc = ?*const fn (?*anyopaque, [*c]const xmlChar, c_int) callconv(.c) void;
pub const ignorableWhitespaceSAXFunc = ?*const fn (?*anyopaque, [*c]const xmlChar, c_int) callconv(.c) void;
pub const processingInstructionSAXFunc = ?*const fn (?*anyopaque, [*c]const xmlChar, [*c]const xmlChar) callconv(.c) void;
pub const commentSAXFunc = ?*const fn (?*anyopaque, [*c]const xmlChar) callconv(.c) void;
pub const warningSAXFunc = ?*const fn (?*anyopaque, [*c]const u8, ...) callconv(.c) void;
pub const errorSAXFunc = ?*const fn (?*anyopaque, [*c]const u8, ...) callconv(.c) void;
pub const fatalErrorSAXFunc = ?*const fn (?*anyopaque, [*c]const u8, ...) callconv(.c) void;
pub const getParameterEntitySAXFunc = ?*const fn (?*anyopaque, [*c]const xmlChar) callconv(.c) xmlEntityPtr;
pub const cdataBlockSAXFunc = ?*const fn (?*anyopaque, [*c]const xmlChar, c_int) callconv(.c) void;
pub const externalSubsetSAXFunc = ?*const fn (?*anyopaque, [*c]const xmlChar, [*c]const xmlChar, [*c]const xmlChar) callconv(.c) void;
pub const startElementNsSAX2Func = ?*const fn (?*anyopaque, [*c]const xmlChar, [*c]const xmlChar, [*c]const xmlChar, c_int, [*c][*c]const xmlChar, c_int, c_int, [*c][*c]const xmlChar) callconv(.c) void;
pub const endElementNsSAX2Func = ?*const fn (?*anyopaque, [*c]const xmlChar, [*c]const xmlChar, [*c]const xmlChar) callconv(.c) void;
pub const struct__xmlError = extern struct {
    domain: c_int = @import("std").mem.zeroes(c_int),
    code: c_int = @import("std").mem.zeroes(c_int),
    message: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    level: xmlErrorLevel = @import("std").mem.zeroes(xmlErrorLevel),
    file: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    line: c_int = @import("std").mem.zeroes(c_int),
    str1: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    str2: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    str3: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    int1: c_int = @import("std").mem.zeroes(c_int),
    int2: c_int = @import("std").mem.zeroes(c_int),
    ctxt: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    node: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
};
pub const xmlError = struct__xmlError;
pub const xmlErrorPtr = [*c]xmlError;
pub const xmlStructuredErrorFunc = ?*const fn (?*anyopaque, xmlErrorPtr) callconv(.c) void;
pub const struct__xmlSAXHandler = extern struct {
    internalSubset: internalSubsetSAXFunc = @import("std").mem.zeroes(internalSubsetSAXFunc),
    isStandalone: isStandaloneSAXFunc = @import("std").mem.zeroes(isStandaloneSAXFunc),
    hasInternalSubset: hasInternalSubsetSAXFunc = @import("std").mem.zeroes(hasInternalSubsetSAXFunc),
    hasExternalSubset: hasExternalSubsetSAXFunc = @import("std").mem.zeroes(hasExternalSubsetSAXFunc),
    resolveEntity: resolveEntitySAXFunc = @import("std").mem.zeroes(resolveEntitySAXFunc),
    getEntity: getEntitySAXFunc = @import("std").mem.zeroes(getEntitySAXFunc),
    entityDecl: entityDeclSAXFunc = @import("std").mem.zeroes(entityDeclSAXFunc),
    notationDecl: notationDeclSAXFunc = @import("std").mem.zeroes(notationDeclSAXFunc),
    attributeDecl: attributeDeclSAXFunc = @import("std").mem.zeroes(attributeDeclSAXFunc),
    elementDecl: elementDeclSAXFunc = @import("std").mem.zeroes(elementDeclSAXFunc),
    unparsedEntityDecl: unparsedEntityDeclSAXFunc = @import("std").mem.zeroes(unparsedEntityDeclSAXFunc),
    setDocumentLocator: setDocumentLocatorSAXFunc = @import("std").mem.zeroes(setDocumentLocatorSAXFunc),
    startDocument: startDocumentSAXFunc = @import("std").mem.zeroes(startDocumentSAXFunc),
    endDocument: endDocumentSAXFunc = @import("std").mem.zeroes(endDocumentSAXFunc),
    startElement: startElementSAXFunc = @import("std").mem.zeroes(startElementSAXFunc),
    endElement: endElementSAXFunc = @import("std").mem.zeroes(endElementSAXFunc),
    reference: referenceSAXFunc = @import("std").mem.zeroes(referenceSAXFunc),
    characters: charactersSAXFunc = @import("std").mem.zeroes(charactersSAXFunc),
    ignorableWhitespace: ignorableWhitespaceSAXFunc = @import("std").mem.zeroes(ignorableWhitespaceSAXFunc),
    processingInstruction: processingInstructionSAXFunc = @import("std").mem.zeroes(processingInstructionSAXFunc),
    comment: commentSAXFunc = @import("std").mem.zeroes(commentSAXFunc),
    warning: warningSAXFunc = @import("std").mem.zeroes(warningSAXFunc),
    @"error": errorSAXFunc = @import("std").mem.zeroes(errorSAXFunc),
    fatalError: fatalErrorSAXFunc = @import("std").mem.zeroes(fatalErrorSAXFunc),
    getParameterEntity: getParameterEntitySAXFunc = @import("std").mem.zeroes(getParameterEntitySAXFunc),
    cdataBlock: cdataBlockSAXFunc = @import("std").mem.zeroes(cdataBlockSAXFunc),
    externalSubset: externalSubsetSAXFunc = @import("std").mem.zeroes(externalSubsetSAXFunc),
    initialized: c_uint = @import("std").mem.zeroes(c_uint),
    _private: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    startElementNs: startElementNsSAX2Func = @import("std").mem.zeroes(startElementNsSAX2Func),
    endElementNs: endElementNsSAX2Func = @import("std").mem.zeroes(endElementNsSAX2Func),
    serror: xmlStructuredErrorFunc = @import("std").mem.zeroes(xmlStructuredErrorFunc),
};
pub const xmlDoc = struct__xmlDoc;
pub const xmlDocPtr = [*c]xmlDoc;
pub const xmlNode = struct__xmlNode;
pub const xmlNodePtr = [*c]xmlNode;
pub const struct__xmlParserNodeInfo = extern struct {
    node: [*c]const struct__xmlNode = @import("std").mem.zeroes([*c]const struct__xmlNode),
    begin_pos: c_ulong = @import("std").mem.zeroes(c_ulong),
    begin_line: c_ulong = @import("std").mem.zeroes(c_ulong),
    end_pos: c_ulong = @import("std").mem.zeroes(c_ulong),
    end_line: c_ulong = @import("std").mem.zeroes(c_ulong),
};
pub const xmlParserNodeInfo = struct__xmlParserNodeInfo;
pub const struct__xmlParserNodeInfoSeq = extern struct {
    maximum: c_ulong = @import("std").mem.zeroes(c_ulong),
    length: c_ulong = @import("std").mem.zeroes(c_ulong),
    buffer: [*c]xmlParserNodeInfo = @import("std").mem.zeroes([*c]xmlParserNodeInfo),
};
pub const xmlParserNodeInfoSeq = struct__xmlParserNodeInfoSeq;
pub const xmlValidityErrorFunc = ?*const fn (?*anyopaque, [*c]const u8, ...) callconv(.c) void;
pub const xmlValidityWarningFunc = ?*const fn (?*anyopaque, [*c]const u8, ...) callconv(.c) void;
pub const struct__xmlValidState = opaque {};
pub const xmlValidState = struct__xmlValidState;
pub const struct__xmlValidCtxt = extern struct {
    userData: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    @"error": xmlValidityErrorFunc = @import("std").mem.zeroes(xmlValidityErrorFunc),
    warning: xmlValidityWarningFunc = @import("std").mem.zeroes(xmlValidityWarningFunc),
    node: xmlNodePtr = @import("std").mem.zeroes(xmlNodePtr),
    nodeNr: c_int = @import("std").mem.zeroes(c_int),
    nodeMax: c_int = @import("std").mem.zeroes(c_int),
    nodeTab: [*c]xmlNodePtr = @import("std").mem.zeroes([*c]xmlNodePtr),
    flags: c_uint = @import("std").mem.zeroes(c_uint),
    doc: xmlDocPtr = @import("std").mem.zeroes(xmlDocPtr),
    valid: c_int = @import("std").mem.zeroes(c_int),
    vstate: ?*xmlValidState = @import("std").mem.zeroes(?*xmlValidState),
    vstateNr: c_int = @import("std").mem.zeroes(c_int),
    vstateMax: c_int = @import("std").mem.zeroes(c_int),
    vstateTab: ?*xmlValidState = @import("std").mem.zeroes(?*xmlValidState),
    am: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    state: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
};
pub const xmlValidCtxt = struct__xmlValidCtxt;
pub const xmlDict = struct__xmlDict_1;
pub const xmlDictPtr = ?*xmlDict;
pub const struct__xmlStartTag = opaque {};
pub const xmlStartTag = struct__xmlStartTag;
pub const struct__xmlHashTable = opaque {};
pub const xmlHashTable = struct__xmlHashTable;
pub const xmlHashTablePtr = ?*xmlHashTable;
pub const xmlAttr = struct__xmlAttr;
pub const xmlAttrPtr = [*c]xmlAttr;
pub const struct__xmlParserCtxt = extern struct {
    sax: [*c]struct__xmlSAXHandler = @import("std").mem.zeroes([*c]struct__xmlSAXHandler),
    userData: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    myDoc: xmlDocPtr = @import("std").mem.zeroes(xmlDocPtr),
    wellFormed: c_int = @import("std").mem.zeroes(c_int),
    replaceEntities: c_int = @import("std").mem.zeroes(c_int),
    version: [*c]const xmlChar = @import("std").mem.zeroes([*c]const xmlChar),
    encoding: [*c]const xmlChar = @import("std").mem.zeroes([*c]const xmlChar),
    standalone: c_int = @import("std").mem.zeroes(c_int),
    html: c_int = @import("std").mem.zeroes(c_int),
    input: xmlParserInputPtr = @import("std").mem.zeroes(xmlParserInputPtr),
    inputNr: c_int = @import("std").mem.zeroes(c_int),
    inputMax: c_int = @import("std").mem.zeroes(c_int),
    inputTab: [*c]xmlParserInputPtr = @import("std").mem.zeroes([*c]xmlParserInputPtr),
    node: xmlNodePtr = @import("std").mem.zeroes(xmlNodePtr),
    nodeNr: c_int = @import("std").mem.zeroes(c_int),
    nodeMax: c_int = @import("std").mem.zeroes(c_int),
    nodeTab: [*c]xmlNodePtr = @import("std").mem.zeroes([*c]xmlNodePtr),
    record_info: c_int = @import("std").mem.zeroes(c_int),
    node_seq: xmlParserNodeInfoSeq = @import("std").mem.zeroes(xmlParserNodeInfoSeq),
    errNo: c_int = @import("std").mem.zeroes(c_int),
    hasExternalSubset: c_int = @import("std").mem.zeroes(c_int),
    hasPErefs: c_int = @import("std").mem.zeroes(c_int),
    external: c_int = @import("std").mem.zeroes(c_int),
    valid: c_int = @import("std").mem.zeroes(c_int),
    validate: c_int = @import("std").mem.zeroes(c_int),
    vctxt: xmlValidCtxt = @import("std").mem.zeroes(xmlValidCtxt),
    instate: xmlParserInputState = @import("std").mem.zeroes(xmlParserInputState),
    token: c_int = @import("std").mem.zeroes(c_int),
    directory: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    name: [*c]const xmlChar = @import("std").mem.zeroes([*c]const xmlChar),
    nameNr: c_int = @import("std").mem.zeroes(c_int),
    nameMax: c_int = @import("std").mem.zeroes(c_int),
    nameTab: [*c][*c]const xmlChar = @import("std").mem.zeroes([*c][*c]const xmlChar),
    nbChars: c_long = @import("std").mem.zeroes(c_long),
    checkIndex: c_long = @import("std").mem.zeroes(c_long),
    keepBlanks: c_int = @import("std").mem.zeroes(c_int),
    disableSAX: c_int = @import("std").mem.zeroes(c_int),
    inSubset: c_int = @import("std").mem.zeroes(c_int),
    intSubName: [*c]const xmlChar = @import("std").mem.zeroes([*c]const xmlChar),
    extSubURI: [*c]xmlChar = @import("std").mem.zeroes([*c]xmlChar),
    extSubSystem: [*c]xmlChar = @import("std").mem.zeroes([*c]xmlChar),
    space: [*c]c_int = @import("std").mem.zeroes([*c]c_int),
    spaceNr: c_int = @import("std").mem.zeroes(c_int),
    spaceMax: c_int = @import("std").mem.zeroes(c_int),
    spaceTab: [*c]c_int = @import("std").mem.zeroes([*c]c_int),
    depth: c_int = @import("std").mem.zeroes(c_int),
    entity: xmlParserInputPtr = @import("std").mem.zeroes(xmlParserInputPtr),
    charset: c_int = @import("std").mem.zeroes(c_int),
    nodelen: c_int = @import("std").mem.zeroes(c_int),
    nodemem: c_int = @import("std").mem.zeroes(c_int),
    pedantic: c_int = @import("std").mem.zeroes(c_int),
    _private: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    loadsubset: c_int = @import("std").mem.zeroes(c_int),
    linenumbers: c_int = @import("std").mem.zeroes(c_int),
    catalogs: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    recovery: c_int = @import("std").mem.zeroes(c_int),
    progressive: c_int = @import("std").mem.zeroes(c_int),
    dict: xmlDictPtr = @import("std").mem.zeroes(xmlDictPtr),
    atts: [*c][*c]const xmlChar = @import("std").mem.zeroes([*c][*c]const xmlChar),
    maxatts: c_int = @import("std").mem.zeroes(c_int),
    docdict: c_int = @import("std").mem.zeroes(c_int),
    str_xml: [*c]const xmlChar = @import("std").mem.zeroes([*c]const xmlChar),
    str_xmlns: [*c]const xmlChar = @import("std").mem.zeroes([*c]const xmlChar),
    str_xml_ns: [*c]const xmlChar = @import("std").mem.zeroes([*c]const xmlChar),
    sax2: c_int = @import("std").mem.zeroes(c_int),
    nsNr: c_int = @import("std").mem.zeroes(c_int),
    nsMax: c_int = @import("std").mem.zeroes(c_int),
    nsTab: [*c][*c]const xmlChar = @import("std").mem.zeroes([*c][*c]const xmlChar),
    attallocs: [*c]c_int = @import("std").mem.zeroes([*c]c_int),
    pushTab: ?*xmlStartTag = @import("std").mem.zeroes(?*xmlStartTag),
    attsDefault: xmlHashTablePtr = @import("std").mem.zeroes(xmlHashTablePtr),
    attsSpecial: xmlHashTablePtr = @import("std").mem.zeroes(xmlHashTablePtr),
    nsWellFormed: c_int = @import("std").mem.zeroes(c_int),
    options: c_int = @import("std").mem.zeroes(c_int),
    dictNames: c_int = @import("std").mem.zeroes(c_int),
    freeElemsNr: c_int = @import("std").mem.zeroes(c_int),
    freeElems: xmlNodePtr = @import("std").mem.zeroes(xmlNodePtr),
    freeAttrsNr: c_int = @import("std").mem.zeroes(c_int),
    freeAttrs: xmlAttrPtr = @import("std").mem.zeroes(xmlAttrPtr),
    lastError: xmlError = @import("std").mem.zeroes(xmlError),
    parseMode: xmlParserMode = @import("std").mem.zeroes(xmlParserMode),
    nbentities: c_ulong = @import("std").mem.zeroes(c_ulong),
    sizeentities: c_ulong = @import("std").mem.zeroes(c_ulong),
    nodeInfo: [*c]xmlParserNodeInfo = @import("std").mem.zeroes([*c]xmlParserNodeInfo),
    nodeInfoNr: c_int = @import("std").mem.zeroes(c_int),
    nodeInfoMax: c_int = @import("std").mem.zeroes(c_int),
    nodeInfoTab: [*c]xmlParserNodeInfo = @import("std").mem.zeroes([*c]xmlParserNodeInfo),
    input_id: c_int = @import("std").mem.zeroes(c_int),
    sizeentcopy: c_ulong = @import("std").mem.zeroes(c_ulong),
    endCheckState: c_int = @import("std").mem.zeroes(c_int),
    nbErrors: c_ushort = @import("std").mem.zeroes(c_ushort),
    nbWarnings: c_ushort = @import("std").mem.zeroes(c_ushort),
};
pub const xmlParserCtxt = struct__xmlParserCtxt;
pub const xmlParserCtxtPtr = [*c]xmlParserCtxt;
pub const xmlSAXHandler = struct__xmlSAXHandler;
pub const xmlSAXHandlerPtr = [*c]xmlSAXHandler;
pub const XML_BUFFER_ALLOC_DOUBLEIT: c_int = 0;
pub const XML_BUFFER_ALLOC_EXACT: c_int = 1;
pub const XML_BUFFER_ALLOC_IMMUTABLE: c_int = 2;
pub const XML_BUFFER_ALLOC_IO: c_int = 3;
pub const XML_BUFFER_ALLOC_HYBRID: c_int = 4;
pub const XML_BUFFER_ALLOC_BOUNDED: c_int = 5;
pub const xmlBufferAllocationScheme = c_uint;
pub const struct__xmlBuffer = extern struct {
    content: [*c]xmlChar = @import("std").mem.zeroes([*c]xmlChar),
    use: c_uint = @import("std").mem.zeroes(c_uint),
    size: c_uint = @import("std").mem.zeroes(c_uint),
    alloc: xmlBufferAllocationScheme = @import("std").mem.zeroes(xmlBufferAllocationScheme),
    contentIO: [*c]xmlChar = @import("std").mem.zeroes([*c]xmlChar),
};
pub const xmlBuffer = struct__xmlBuffer;
pub const xmlBufferPtr = [*c]xmlBuffer;
pub extern fn xmlBufContent(buf: ?*const xmlBuf) [*c]xmlChar;
pub extern fn xmlBufEnd(buf: xmlBufPtr) [*c]xmlChar;
pub extern fn xmlBufUse(buf: xmlBufPtr) usize;
pub extern fn xmlBufShrink(buf: xmlBufPtr, len: usize) usize;
pub const XML_ELEMENT_NODE: c_int = 1;
pub const XML_ATTRIBUTE_NODE: c_int = 2;
pub const XML_TEXT_NODE: c_int = 3;
pub const XML_CDATA_SECTION_NODE: c_int = 4;
pub const XML_ENTITY_REF_NODE: c_int = 5;
pub const XML_ENTITY_NODE: c_int = 6;
pub const XML_PI_NODE: c_int = 7;
pub const XML_COMMENT_NODE: c_int = 8;
pub const XML_DOCUMENT_NODE: c_int = 9;
pub const XML_DOCUMENT_TYPE_NODE: c_int = 10;
pub const XML_DOCUMENT_FRAG_NODE: c_int = 11;
pub const XML_NOTATION_NODE: c_int = 12;
pub const XML_HTML_DOCUMENT_NODE: c_int = 13;
pub const XML_DTD_NODE: c_int = 14;
pub const XML_ELEMENT_DECL: c_int = 15;
pub const XML_ATTRIBUTE_DECL: c_int = 16;
pub const XML_ENTITY_DECL: c_int = 17;
pub const XML_NAMESPACE_DECL: c_int = 18;
pub const XML_XINCLUDE_START: c_int = 19;
pub const XML_XINCLUDE_END: c_int = 20;
pub const xmlElementType = c_uint;
pub const struct__xmlNotation = extern struct {
    name: [*c]const xmlChar = @import("std").mem.zeroes([*c]const xmlChar),
    PublicID: [*c]const xmlChar = @import("std").mem.zeroes([*c]const xmlChar),
    SystemID: [*c]const xmlChar = @import("std").mem.zeroes([*c]const xmlChar),
};
pub const xmlNotation = struct__xmlNotation;
pub const xmlNotationPtr = [*c]xmlNotation;
pub const XML_ATTRIBUTE_CDATA: c_int = 1;
pub const XML_ATTRIBUTE_ID: c_int = 2;
pub const XML_ATTRIBUTE_IDREF: c_int = 3;
pub const XML_ATTRIBUTE_IDREFS: c_int = 4;
pub const XML_ATTRIBUTE_ENTITY: c_int = 5;
pub const XML_ATTRIBUTE_ENTITIES: c_int = 6;
pub const XML_ATTRIBUTE_NMTOKEN: c_int = 7;
pub const XML_ATTRIBUTE_NMTOKENS: c_int = 8;
pub const XML_ATTRIBUTE_ENUMERATION: c_int = 9;
pub const XML_ATTRIBUTE_NOTATION: c_int = 10;
pub const xmlAttributeType = c_uint;
pub const XML_ATTRIBUTE_NONE: c_int = 1;
pub const XML_ATTRIBUTE_REQUIRED: c_int = 2;
pub const XML_ATTRIBUTE_IMPLIED: c_int = 3;
pub const XML_ATTRIBUTE_FIXED: c_int = 4;
pub const xmlAttributeDefault = c_uint;
pub const struct__xmlAttribute = extern struct {
    _private: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    type: xmlElementType = @import("std").mem.zeroes(xmlElementType),
    name: [*c]const xmlChar = @import("std").mem.zeroes([*c]const xmlChar),
    children: [*c]struct__xmlNode = @import("std").mem.zeroes([*c]struct__xmlNode),
    last: [*c]struct__xmlNode = @import("std").mem.zeroes([*c]struct__xmlNode),
    parent: [*c]struct__xmlDtd = @import("std").mem.zeroes([*c]struct__xmlDtd),
    next: [*c]struct__xmlNode = @import("std").mem.zeroes([*c]struct__xmlNode),
    prev: [*c]struct__xmlNode = @import("std").mem.zeroes([*c]struct__xmlNode),
    doc: [*c]struct__xmlDoc = @import("std").mem.zeroes([*c]struct__xmlDoc),
    nexth: [*c]struct__xmlAttribute = @import("std").mem.zeroes([*c]struct__xmlAttribute),
    atype: xmlAttributeType = @import("std").mem.zeroes(xmlAttributeType),
    def: xmlAttributeDefault = @import("std").mem.zeroes(xmlAttributeDefault),
    defaultValue: [*c]const xmlChar = @import("std").mem.zeroes([*c]const xmlChar),
    tree: xmlEnumerationPtr = @import("std").mem.zeroes(xmlEnumerationPtr),
    prefix: [*c]const xmlChar = @import("std").mem.zeroes([*c]const xmlChar),
    elem: [*c]const xmlChar = @import("std").mem.zeroes([*c]const xmlChar),
};
pub const xmlAttribute = struct__xmlAttribute;
pub const xmlAttributePtr = [*c]xmlAttribute;
pub const XML_ELEMENT_CONTENT_PCDATA: c_int = 1;
pub const XML_ELEMENT_CONTENT_ELEMENT: c_int = 2;
pub const XML_ELEMENT_CONTENT_SEQ: c_int = 3;
pub const XML_ELEMENT_CONTENT_OR: c_int = 4;
pub const xmlElementContentType = c_uint;
pub const XML_ELEMENT_CONTENT_ONCE: c_int = 1;
pub const XML_ELEMENT_CONTENT_OPT: c_int = 2;
pub const XML_ELEMENT_CONTENT_MULT: c_int = 3;
pub const XML_ELEMENT_CONTENT_PLUS: c_int = 4;
pub const xmlElementContentOccur = c_uint;
pub const XML_ELEMENT_TYPE_UNDEFINED: c_int = 0;
pub const XML_ELEMENT_TYPE_EMPTY: c_int = 1;
pub const XML_ELEMENT_TYPE_ANY: c_int = 2;
pub const XML_ELEMENT_TYPE_MIXED: c_int = 3;
pub const XML_ELEMENT_TYPE_ELEMENT: c_int = 4;
pub const xmlElementTypeVal = c_uint;
pub const struct__xmlElement = extern struct {
    _private: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    type: xmlElementType = @import("std").mem.zeroes(xmlElementType),
    name: [*c]const xmlChar = @import("std").mem.zeroes([*c]const xmlChar),
    children: [*c]struct__xmlNode = @import("std").mem.zeroes([*c]struct__xmlNode),
    last: [*c]struct__xmlNode = @import("std").mem.zeroes([*c]struct__xmlNode),
    parent: [*c]struct__xmlDtd = @import("std").mem.zeroes([*c]struct__xmlDtd),
    next: [*c]struct__xmlNode = @import("std").mem.zeroes([*c]struct__xmlNode),
    prev: [*c]struct__xmlNode = @import("std").mem.zeroes([*c]struct__xmlNode),
    doc: [*c]struct__xmlDoc = @import("std").mem.zeroes([*c]struct__xmlDoc),
    etype: xmlElementTypeVal = @import("std").mem.zeroes(xmlElementTypeVal),
    content: xmlElementContentPtr = @import("std").mem.zeroes(xmlElementContentPtr),
    attributes: xmlAttributePtr = @import("std").mem.zeroes(xmlAttributePtr),
    prefix: [*c]const xmlChar = @import("std").mem.zeroes([*c]const xmlChar),
    contModel: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
};
pub const xmlElement = struct__xmlElement;
pub const xmlElementPtr = [*c]xmlElement;
pub const xmlNsPtr = [*c]xmlNs;
pub const xmlDtd = struct__xmlDtd;
pub const xmlDtdPtr = [*c]xmlDtd;
pub const struct__xmlID = extern struct {
    next: [*c]struct__xmlID = @import("std").mem.zeroes([*c]struct__xmlID),
    value: [*c]const xmlChar = @import("std").mem.zeroes([*c]const xmlChar),
    attr: xmlAttrPtr = @import("std").mem.zeroes(xmlAttrPtr),
    name: [*c]const xmlChar = @import("std").mem.zeroes([*c]const xmlChar),
    lineno: c_int = @import("std").mem.zeroes(c_int),
    doc: [*c]struct__xmlDoc = @import("std").mem.zeroes([*c]struct__xmlDoc),
};
pub const xmlID = struct__xmlID;
pub const xmlIDPtr = [*c]xmlID;
pub const struct__xmlRef = extern struct {
    next: [*c]struct__xmlRef = @import("std").mem.zeroes([*c]struct__xmlRef),
    value: [*c]const xmlChar = @import("std").mem.zeroes([*c]const xmlChar),
    attr: xmlAttrPtr = @import("std").mem.zeroes(xmlAttrPtr),
    name: [*c]const xmlChar = @import("std").mem.zeroes([*c]const xmlChar),
    lineno: c_int = @import("std").mem.zeroes(c_int),
};
pub const xmlRef = struct__xmlRef;
pub const xmlRefPtr = [*c]xmlRef;
pub const XML_DOC_WELLFORMED: c_int = 1;
pub const XML_DOC_NSVALID: c_int = 2;
pub const XML_DOC_OLD10: c_int = 4;
pub const XML_DOC_DTDVALID: c_int = 8;
pub const XML_DOC_XINCLUDE: c_int = 16;
pub const XML_DOC_USERBUILT: c_int = 32;
pub const XML_DOC_INTERNAL: c_int = 64;
pub const XML_DOC_HTML: c_int = 128;
pub const xmlDocProperties = c_uint;
pub const xmlDOMWrapCtxt = struct__xmlDOMWrapCtxt;
pub const xmlDOMWrapCtxtPtr = [*c]xmlDOMWrapCtxt;
pub const xmlDOMWrapAcquireNsFunction = ?*const fn (xmlDOMWrapCtxtPtr, xmlNodePtr, [*c]const xmlChar, [*c]const xmlChar) callconv(.c) xmlNsPtr;
pub const struct__xmlDOMWrapCtxt = extern struct {
    _private: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    type: c_int = @import("std").mem.zeroes(c_int),
    namespaceMap: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    getNsForNodeFunc: xmlDOMWrapAcquireNsFunction = @import("std").mem.zeroes(xmlDOMWrapAcquireNsFunction),
};
pub extern fn xmlValidateNCName(value: [*c]const xmlChar, space: c_int) c_int;
pub extern fn xmlValidateQName(value: [*c]const xmlChar, space: c_int) c_int;
pub extern fn xmlValidateName(value: [*c]const xmlChar, space: c_int) c_int;
pub extern fn xmlValidateNMToken(value: [*c]const xmlChar, space: c_int) c_int;
pub extern fn xmlBuildQName(ncname: [*c]const xmlChar, prefix: [*c]const xmlChar, memory: [*c]xmlChar, len: c_int) [*c]xmlChar;
pub extern fn xmlSplitQName2(name: [*c]const xmlChar, prefix: [*c][*c]xmlChar) [*c]xmlChar;
pub extern fn xmlSplitQName3(name: [*c]const xmlChar, len: [*c]c_int) [*c]const xmlChar;
pub extern fn xmlSetBufferAllocationScheme(scheme: xmlBufferAllocationScheme) void;
pub extern fn xmlGetBufferAllocationScheme() xmlBufferAllocationScheme;
pub extern fn xmlBufferCreate() xmlBufferPtr;
pub extern fn xmlBufferCreateSize(size: usize) xmlBufferPtr;
pub extern fn xmlBufferCreateStatic(mem: ?*anyopaque, size: usize) xmlBufferPtr;
pub extern fn xmlBufferResize(buf: xmlBufferPtr, size: c_uint) c_int;
pub extern fn xmlBufferFree(buf: xmlBufferPtr) void;
pub extern fn xmlBufferDump(file: [*c]FILE, buf: xmlBufferPtr) c_int;
pub extern fn xmlBufferAdd(buf: xmlBufferPtr, str: [*c]const xmlChar, len: c_int) c_int;
pub extern fn xmlBufferAddHead(buf: xmlBufferPtr, str: [*c]const xmlChar, len: c_int) c_int;
pub extern fn xmlBufferCat(buf: xmlBufferPtr, str: [*c]const xmlChar) c_int;
pub extern fn xmlBufferCCat(buf: xmlBufferPtr, str: [*c]const u8) c_int;
pub extern fn xmlBufferShrink(buf: xmlBufferPtr, len: c_uint) c_int;
pub extern fn xmlBufferGrow(buf: xmlBufferPtr, len: c_uint) c_int;
pub extern fn xmlBufferEmpty(buf: xmlBufferPtr) void;
pub extern fn xmlBufferContent(buf: [*c]const xmlBuffer) [*c]const xmlChar;
pub extern fn xmlBufferDetach(buf: xmlBufferPtr) [*c]xmlChar;
pub extern fn xmlBufferSetAllocationScheme(buf: xmlBufferPtr, scheme: xmlBufferAllocationScheme) void;
pub extern fn xmlBufferLength(buf: [*c]const xmlBuffer) c_int;
pub extern fn xmlCreateIntSubset(doc: xmlDocPtr, name: [*c]const xmlChar, ExternalID: [*c]const xmlChar, SystemID: [*c]const xmlChar) xmlDtdPtr;
pub extern fn xmlNewDtd(doc: xmlDocPtr, name: [*c]const xmlChar, ExternalID: [*c]const xmlChar, SystemID: [*c]const xmlChar) xmlDtdPtr;
pub extern fn xmlGetIntSubset(doc: [*c]const xmlDoc) xmlDtdPtr;
pub extern fn xmlFreeDtd(cur: xmlDtdPtr) void;
pub extern fn xmlNewNs(node: xmlNodePtr, href: [*c]const xmlChar, prefix: [*c]const xmlChar) xmlNsPtr;
pub extern fn xmlFreeNs(cur: xmlNsPtr) void;
pub extern fn xmlFreeNsList(cur: xmlNsPtr) void;
pub extern fn xmlNewDoc(version: [*c]const xmlChar) xmlDocPtr;
pub extern fn xmlFreeDoc(cur: xmlDocPtr) void;
pub extern fn xmlNewDocProp(doc: xmlDocPtr, name: [*c]const xmlChar, value: [*c]const xmlChar) xmlAttrPtr;
pub extern fn xmlNewProp(node: xmlNodePtr, name: [*c]const xmlChar, value: [*c]const xmlChar) xmlAttrPtr;
pub extern fn xmlNewNsProp(node: xmlNodePtr, ns: xmlNsPtr, name: [*c]const xmlChar, value: [*c]const xmlChar) xmlAttrPtr;
pub extern fn xmlNewNsPropEatName(node: xmlNodePtr, ns: xmlNsPtr, name: [*c]xmlChar, value: [*c]const xmlChar) xmlAttrPtr;
pub extern fn xmlFreePropList(cur: xmlAttrPtr) void;
pub extern fn xmlFreeProp(cur: xmlAttrPtr) void;
pub extern fn xmlCopyProp(target: xmlNodePtr, cur: xmlAttrPtr) xmlAttrPtr;
pub extern fn xmlCopyPropList(target: xmlNodePtr, cur: xmlAttrPtr) xmlAttrPtr;
pub extern fn xmlCopyDtd(dtd: xmlDtdPtr) xmlDtdPtr;
pub extern fn xmlCopyDoc(doc: xmlDocPtr, recursive: c_int) xmlDocPtr;
pub extern fn xmlNewDocNode(doc: xmlDocPtr, ns: xmlNsPtr, name: [*c]const xmlChar, content: [*c]const xmlChar) xmlNodePtr;
pub extern fn xmlNewDocNodeEatName(doc: xmlDocPtr, ns: xmlNsPtr, name: [*c]xmlChar, content: [*c]const xmlChar) xmlNodePtr;
pub extern fn xmlNewNode(ns: xmlNsPtr, name: [*c]const xmlChar) xmlNodePtr;
pub extern fn xmlNewNodeEatName(ns: xmlNsPtr, name: [*c]xmlChar) xmlNodePtr;
pub extern fn xmlNewChild(parent: xmlNodePtr, ns: xmlNsPtr, name: [*c]const xmlChar, content: [*c]const xmlChar) xmlNodePtr;
pub extern fn xmlNewDocText(doc: [*c]const xmlDoc, content: [*c]const xmlChar) xmlNodePtr;
pub extern fn xmlNewText(content: [*c]const xmlChar) xmlNodePtr;
pub extern fn xmlNewDocPI(doc: xmlDocPtr, name: [*c]const xmlChar, content: [*c]const xmlChar) xmlNodePtr;
pub extern fn xmlNewPI(name: [*c]const xmlChar, content: [*c]const xmlChar) xmlNodePtr;
pub extern fn xmlNewDocTextLen(doc: xmlDocPtr, content: [*c]const xmlChar, len: c_int) xmlNodePtr;
pub extern fn xmlNewTextLen(content: [*c]const xmlChar, len: c_int) xmlNodePtr;
pub extern fn xmlNewDocComment(doc: xmlDocPtr, content: [*c]const xmlChar) xmlNodePtr;
pub extern fn xmlNewComment(content: [*c]const xmlChar) xmlNodePtr;
pub extern fn xmlNewCDataBlock(doc: xmlDocPtr, content: [*c]const xmlChar, len: c_int) xmlNodePtr;
pub extern fn xmlNewCharRef(doc: xmlDocPtr, name: [*c]const xmlChar) xmlNodePtr;
pub extern fn xmlNewReference(doc: [*c]const xmlDoc, name: [*c]const xmlChar) xmlNodePtr;
pub extern fn xmlCopyNode(node: xmlNodePtr, recursive: c_int) xmlNodePtr;
pub extern fn xmlDocCopyNode(node: xmlNodePtr, doc: xmlDocPtr, recursive: c_int) xmlNodePtr;
pub extern fn xmlDocCopyNodeList(doc: xmlDocPtr, node: xmlNodePtr) xmlNodePtr;
pub extern fn xmlCopyNodeList(node: xmlNodePtr) xmlNodePtr;
pub extern fn xmlNewTextChild(parent: xmlNodePtr, ns: xmlNsPtr, name: [*c]const xmlChar, content: [*c]const xmlChar) xmlNodePtr;
pub extern fn xmlNewDocRawNode(doc: xmlDocPtr, ns: xmlNsPtr, name: [*c]const xmlChar, content: [*c]const xmlChar) xmlNodePtr;
pub extern fn xmlNewDocFragment(doc: xmlDocPtr) xmlNodePtr;
pub extern fn xmlGetLineNo(node: [*c]const xmlNode) c_long;
pub extern fn xmlGetNodePath(node: [*c]const xmlNode) [*c]xmlChar;
pub extern fn xmlDocGetRootElement(doc: [*c]const xmlDoc) xmlNodePtr;
pub extern fn xmlGetLastChild(parent: [*c]const xmlNode) xmlNodePtr;
pub extern fn xmlNodeIsText(node: [*c]const xmlNode) c_int;
pub extern fn xmlIsBlankNode(node: [*c]const xmlNode) c_int;
pub extern fn xmlDocSetRootElement(doc: xmlDocPtr, root: xmlNodePtr) xmlNodePtr;
pub extern fn xmlNodeSetName(cur: xmlNodePtr, name: [*c]const xmlChar) void;
pub extern fn xmlAddChild(parent: xmlNodePtr, cur: xmlNodePtr) xmlNodePtr;
pub extern fn xmlAddChildList(parent: xmlNodePtr, cur: xmlNodePtr) xmlNodePtr;
pub extern fn xmlReplaceNode(old: xmlNodePtr, cur: xmlNodePtr) xmlNodePtr;
pub extern fn xmlAddPrevSibling(cur: xmlNodePtr, elem: xmlNodePtr) xmlNodePtr;
pub extern fn xmlAddSibling(cur: xmlNodePtr, elem: xmlNodePtr) xmlNodePtr;
pub extern fn xmlAddNextSibling(cur: xmlNodePtr, elem: xmlNodePtr) xmlNodePtr;
pub extern fn xmlUnlinkNode(cur: xmlNodePtr) void;
pub extern fn xmlTextMerge(first: xmlNodePtr, second: xmlNodePtr) xmlNodePtr;
pub extern fn xmlTextConcat(node: xmlNodePtr, content: [*c]const xmlChar, len: c_int) c_int;
pub extern fn xmlFreeNodeList(cur: xmlNodePtr) void;
pub extern fn xmlFreeNode(cur: xmlNodePtr) void;
pub extern fn xmlSetTreeDoc(tree: xmlNodePtr, doc: xmlDocPtr) void;
pub extern fn xmlSetListDoc(list: xmlNodePtr, doc: xmlDocPtr) void;
pub extern fn xmlSearchNs(doc: xmlDocPtr, node: xmlNodePtr, nameSpace: [*c]const xmlChar) xmlNsPtr;
pub extern fn xmlSearchNsByHref(doc: xmlDocPtr, node: xmlNodePtr, href: [*c]const xmlChar) xmlNsPtr;
pub extern fn xmlGetNsList(doc: [*c]const xmlDoc, node: [*c]const xmlNode) [*c]xmlNsPtr;
pub extern fn xmlSetNs(node: xmlNodePtr, ns: xmlNsPtr) void;
pub extern fn xmlCopyNamespace(cur: xmlNsPtr) xmlNsPtr;
pub extern fn xmlCopyNamespaceList(cur: xmlNsPtr) xmlNsPtr;
pub extern fn xmlSetProp(node: xmlNodePtr, name: [*c]const xmlChar, value: [*c]const xmlChar) xmlAttrPtr;
pub extern fn xmlSetNsProp(node: xmlNodePtr, ns: xmlNsPtr, name: [*c]const xmlChar, value: [*c]const xmlChar) xmlAttrPtr;
pub extern fn xmlGetNoNsProp(node: [*c]const xmlNode, name: [*c]const xmlChar) [*c]xmlChar;
pub extern fn xmlGetProp(node: [*c]const xmlNode, name: [*c]const xmlChar) [*c]xmlChar;
pub extern fn xmlHasProp(node: [*c]const xmlNode, name: [*c]const xmlChar) xmlAttrPtr;
pub extern fn xmlHasNsProp(node: [*c]const xmlNode, name: [*c]const xmlChar, nameSpace: [*c]const xmlChar) xmlAttrPtr;
pub extern fn xmlGetNsProp(node: [*c]const xmlNode, name: [*c]const xmlChar, nameSpace: [*c]const xmlChar) [*c]xmlChar;
pub extern fn xmlStringGetNodeList(doc: [*c]const xmlDoc, value: [*c]const xmlChar) xmlNodePtr;
pub extern fn xmlStringLenGetNodeList(doc: [*c]const xmlDoc, value: [*c]const xmlChar, len: c_int) xmlNodePtr;
pub extern fn xmlNodeListGetString(doc: xmlDocPtr, list: [*c]const xmlNode, inLine: c_int) [*c]xmlChar;
pub extern fn xmlNodeListGetRawString(doc: [*c]const xmlDoc, list: [*c]const xmlNode, inLine: c_int) [*c]xmlChar;
pub extern fn xmlNodeSetContent(cur: xmlNodePtr, content: [*c]const xmlChar) void;
pub extern fn xmlNodeSetContentLen(cur: xmlNodePtr, content: [*c]const xmlChar, len: c_int) void;
pub extern fn xmlNodeAddContent(cur: xmlNodePtr, content: [*c]const xmlChar) void;
pub extern fn xmlNodeAddContentLen(cur: xmlNodePtr, content: [*c]const xmlChar, len: c_int) void;
pub extern fn xmlNodeGetContent(cur: [*c]const xmlNode) [*c]xmlChar;
pub extern fn xmlNodeBufGetContent(buffer: xmlBufferPtr, cur: [*c]const xmlNode) c_int;
pub extern fn xmlBufGetNodeContent(buf: xmlBufPtr, cur: [*c]const xmlNode) c_int;
pub extern fn xmlNodeGetLang(cur: [*c]const xmlNode) [*c]xmlChar;
pub extern fn xmlNodeGetSpacePreserve(cur: [*c]const xmlNode) c_int;
pub extern fn xmlNodeSetLang(cur: xmlNodePtr, lang: [*c]const xmlChar) void;
pub extern fn xmlNodeSetSpacePreserve(cur: xmlNodePtr, val: c_int) void;
pub extern fn xmlNodeGetBase(doc: [*c]const xmlDoc, cur: [*c]const xmlNode) [*c]xmlChar;
pub extern fn xmlNodeSetBase(cur: xmlNodePtr, uri: [*c]const xmlChar) void;
pub extern fn xmlRemoveProp(cur: xmlAttrPtr) c_int;
pub extern fn xmlUnsetNsProp(node: xmlNodePtr, ns: xmlNsPtr, name: [*c]const xmlChar) c_int;
pub extern fn xmlUnsetProp(node: xmlNodePtr, name: [*c]const xmlChar) c_int;
pub extern fn xmlBufferWriteCHAR(buf: xmlBufferPtr, string: [*c]const xmlChar) void;
pub extern fn xmlBufferWriteChar(buf: xmlBufferPtr, string: [*c]const u8) void;
pub extern fn xmlBufferWriteQuotedString(buf: xmlBufferPtr, string: [*c]const xmlChar) void;
pub extern fn xmlReconciliateNs(doc: xmlDocPtr, tree: xmlNodePtr) c_int;
pub extern fn xmlIsXHTML(systemID: [*c]const xmlChar, publicID: [*c]const xmlChar) c_int;
pub extern fn xmlGetDocCompressMode(doc: [*c]const xmlDoc) c_int;
pub extern fn xmlSetDocCompressMode(doc: xmlDocPtr, mode: c_int) void;
pub extern fn xmlGetCompressMode() c_int;
pub extern fn xmlSetCompressMode(mode: c_int) void;
pub extern fn xmlDOMWrapNewCtxt() xmlDOMWrapCtxtPtr;
pub extern fn xmlDOMWrapFreeCtxt(ctxt: xmlDOMWrapCtxtPtr) void;
pub extern fn xmlDOMWrapReconcileNamespaces(ctxt: xmlDOMWrapCtxtPtr, elem: xmlNodePtr, options: c_int) c_int;
pub extern fn xmlDOMWrapAdoptNode(ctxt: xmlDOMWrapCtxtPtr, sourceDoc: xmlDocPtr, node: xmlNodePtr, destDoc: xmlDocPtr, destParent: xmlNodePtr, options: c_int) c_int;
pub extern fn xmlDOMWrapRemoveNode(ctxt: xmlDOMWrapCtxtPtr, doc: xmlDocPtr, node: xmlNodePtr, options: c_int) c_int;
pub extern fn xmlDOMWrapCloneNode(ctxt: xmlDOMWrapCtxtPtr, sourceDoc: xmlDocPtr, node: xmlNodePtr, clonedNode: [*c]xmlNodePtr, destDoc: xmlDocPtr, destParent: xmlNodePtr, deep: c_int, options: c_int) c_int;
pub extern fn xmlChildElementCount(parent: xmlNodePtr) c_ulong;
pub extern fn xmlNextElementSibling(node: xmlNodePtr) xmlNodePtr;
pub extern fn xmlFirstElementChild(parent: xmlNodePtr) xmlNodePtr;
pub extern fn xmlLastElementChild(parent: xmlNodePtr) xmlNodePtr;
pub extern fn xmlPreviousElementSibling(node: xmlNodePtr) xmlNodePtr;
pub const xmlFreeFunc = ?*const fn (?*anyopaque) callconv(.c) void;
pub const xmlMallocFunc = ?*const fn (usize) callconv(.c) ?*anyopaque;
pub const xmlReallocFunc = ?*const fn (?*anyopaque, usize) callconv(.c) ?*anyopaque;
pub const xmlStrdupFunc = ?*const fn ([*c]const u8) callconv(.c) [*c]u8;
pub extern fn xmlMemSetup(freeFunc: xmlFreeFunc, mallocFunc: xmlMallocFunc, reallocFunc: xmlReallocFunc, strdupFunc: xmlStrdupFunc) c_int;
pub extern fn xmlMemGet(freeFunc: [*c]xmlFreeFunc, mallocFunc: [*c]xmlMallocFunc, reallocFunc: [*c]xmlReallocFunc, strdupFunc: [*c]xmlStrdupFunc) c_int;
pub extern fn xmlGcMemSetup(freeFunc: xmlFreeFunc, mallocFunc: xmlMallocFunc, mallocAtomicFunc: xmlMallocFunc, reallocFunc: xmlReallocFunc, strdupFunc: xmlStrdupFunc) c_int;
pub extern fn xmlGcMemGet(freeFunc: [*c]xmlFreeFunc, mallocFunc: [*c]xmlMallocFunc, mallocAtomicFunc: [*c]xmlMallocFunc, reallocFunc: [*c]xmlReallocFunc, strdupFunc: [*c]xmlStrdupFunc) c_int;
pub extern fn xmlInitMemory() c_int;
pub extern fn xmlCleanupMemory() void;
pub extern fn xmlMemSize(ptr: ?*anyopaque) usize;
pub extern fn xmlMemUsed() c_int;
pub extern fn xmlMemBlocks() c_int;
pub extern fn xmlMemDisplay(fp: [*c]FILE) void;
pub extern fn xmlMemDisplayLast(fp: [*c]FILE, nbBytes: c_long) void;
pub extern fn xmlMemShow(fp: [*c]FILE, nr: c_int) void;
pub extern fn xmlMemoryDump() void;
pub extern fn xmlMemMalloc(size: usize) ?*anyopaque;
pub extern fn xmlMemRealloc(ptr: ?*anyopaque, size: usize) ?*anyopaque;
pub extern fn xmlMemFree(ptr: ?*anyopaque) void;
pub extern fn xmlMemoryStrdup(str: [*c]const u8) [*c]u8;
pub extern fn xmlMallocLoc(size: usize, file: [*c]const u8, line: c_int) ?*anyopaque;
pub extern fn xmlReallocLoc(ptr: ?*anyopaque, size: usize, file: [*c]const u8, line: c_int) ?*anyopaque;
pub extern fn xmlMallocAtomicLoc(size: usize, file: [*c]const u8, line: c_int) ?*anyopaque;
pub extern fn xmlMemStrdupLoc(str: [*c]const u8, file: [*c]const u8, line: c_int) [*c]u8;
pub const struct__xmlMutex = opaque {};
pub const xmlMutex = struct__xmlMutex;
pub const xmlMutexPtr = ?*xmlMutex;
pub const struct__xmlRMutex = opaque {};
pub const xmlRMutex = struct__xmlRMutex;
pub const xmlRMutexPtr = ?*xmlRMutex;
pub const max_align_t = extern struct {
    __clang_max_align_nonce1: c_longlong align(8) = @import("std").mem.zeroes(c_longlong),
    __clang_max_align_nonce2: c_longdouble align(16) = @import("std").mem.zeroes(c_longdouble),
};
pub extern fn xmlInitializeDict() c_int;
pub extern fn xmlDictCreate() xmlDictPtr;
pub extern fn xmlDictSetLimit(dict: xmlDictPtr, limit: usize) usize;
pub extern fn xmlDictGetUsage(dict: xmlDictPtr) usize;
pub extern fn xmlDictCreateSub(sub: xmlDictPtr) xmlDictPtr;
pub extern fn xmlDictReference(dict: xmlDictPtr) c_int;
pub extern fn xmlDictFree(dict: xmlDictPtr) void;
pub extern fn xmlDictLookup(dict: xmlDictPtr, name: [*c]const xmlChar, len: c_int) [*c]const xmlChar;
pub extern fn xmlDictExists(dict: xmlDictPtr, name: [*c]const xmlChar, len: c_int) [*c]const xmlChar;
pub extern fn xmlDictQLookup(dict: xmlDictPtr, prefix: [*c]const xmlChar, name: [*c]const xmlChar) [*c]const xmlChar;
pub extern fn xmlDictOwns(dict: xmlDictPtr, str: [*c]const xmlChar) c_int;
pub extern fn xmlDictSize(dict: xmlDictPtr) c_int;
pub extern fn xmlDictCleanup() void;
pub const xmlHashDeallocator = ?*const fn (?*anyopaque, [*c]const xmlChar) callconv(.c) void;
pub const xmlHashCopier = ?*const fn (?*anyopaque, [*c]const xmlChar) callconv(.c) ?*anyopaque;
pub const xmlHashScanner = ?*const fn (?*anyopaque, ?*anyopaque, [*c]const xmlChar) callconv(.c) void;
pub const xmlHashScannerFull = ?*const fn (?*anyopaque, ?*anyopaque, [*c]const xmlChar, [*c]const xmlChar, [*c]const xmlChar) callconv(.c) void;
pub extern fn xmlHashCreate(size: c_int) xmlHashTablePtr;
pub extern fn xmlHashCreateDict(size: c_int, dict: xmlDictPtr) xmlHashTablePtr;
pub extern fn xmlHashFree(table: xmlHashTablePtr, f: xmlHashDeallocator) void;
pub extern fn xmlHashDefaultDeallocator(entry: ?*anyopaque, name: [*c]const xmlChar) void;
pub extern fn xmlHashAddEntry(table: xmlHashTablePtr, name: [*c]const xmlChar, userdata: ?*anyopaque) c_int;
pub extern fn xmlHashUpdateEntry(table: xmlHashTablePtr, name: [*c]const xmlChar, userdata: ?*anyopaque, f: xmlHashDeallocator) c_int;
pub extern fn xmlHashAddEntry2(table: xmlHashTablePtr, name: [*c]const xmlChar, name2: [*c]const xmlChar, userdata: ?*anyopaque) c_int;
pub extern fn xmlHashUpdateEntry2(table: xmlHashTablePtr, name: [*c]const xmlChar, name2: [*c]const xmlChar, userdata: ?*anyopaque, f: xmlHashDeallocator) c_int;
pub extern fn xmlHashAddEntry3(table: xmlHashTablePtr, name: [*c]const xmlChar, name2: [*c]const xmlChar, name3: [*c]const xmlChar, userdata: ?*anyopaque) c_int;
pub extern fn xmlHashUpdateEntry3(table: xmlHashTablePtr, name: [*c]const xmlChar, name2: [*c]const xmlChar, name3: [*c]const xmlChar, userdata: ?*anyopaque, f: xmlHashDeallocator) c_int;
pub extern fn xmlHashRemoveEntry(table: xmlHashTablePtr, name: [*c]const xmlChar, f: xmlHashDeallocator) c_int;
pub extern fn xmlHashRemoveEntry2(table: xmlHashTablePtr, name: [*c]const xmlChar, name2: [*c]const xmlChar, f: xmlHashDeallocator) c_int;
pub extern fn xmlHashRemoveEntry3(table: xmlHashTablePtr, name: [*c]const xmlChar, name2: [*c]const xmlChar, name3: [*c]const xmlChar, f: xmlHashDeallocator) c_int;
pub extern fn xmlHashLookup(table: xmlHashTablePtr, name: [*c]const xmlChar) ?*anyopaque;
pub extern fn xmlHashLookup2(table: xmlHashTablePtr, name: [*c]const xmlChar, name2: [*c]const xmlChar) ?*anyopaque;
pub extern fn xmlHashLookup3(table: xmlHashTablePtr, name: [*c]const xmlChar, name2: [*c]const xmlChar, name3: [*c]const xmlChar) ?*anyopaque;
pub extern fn xmlHashQLookup(table: xmlHashTablePtr, name: [*c]const xmlChar, prefix: [*c]const xmlChar) ?*anyopaque;
pub extern fn xmlHashQLookup2(table: xmlHashTablePtr, name: [*c]const xmlChar, prefix: [*c]const xmlChar, name2: [*c]const xmlChar, prefix2: [*c]const xmlChar) ?*anyopaque;
pub extern fn xmlHashQLookup3(table: xmlHashTablePtr, name: [*c]const xmlChar, prefix: [*c]const xmlChar, name2: [*c]const xmlChar, prefix2: [*c]const xmlChar, name3: [*c]const xmlChar, prefix3: [*c]const xmlChar) ?*anyopaque;
pub extern fn xmlHashCopy(table: xmlHashTablePtr, f: xmlHashCopier) xmlHashTablePtr;
pub extern fn xmlHashSize(table: xmlHashTablePtr) c_int;
pub extern fn xmlHashScan(table: xmlHashTablePtr, f: xmlHashScanner, data: ?*anyopaque) void;
pub extern fn xmlHashScan3(table: xmlHashTablePtr, name: [*c]const xmlChar, name2: [*c]const xmlChar, name3: [*c]const xmlChar, f: xmlHashScanner, data: ?*anyopaque) void;
pub extern fn xmlHashScanFull(table: xmlHashTablePtr, f: xmlHashScannerFull, data: ?*anyopaque) void;
pub extern fn xmlHashScanFull3(table: xmlHashTablePtr, name: [*c]const xmlChar, name2: [*c]const xmlChar, name3: [*c]const xmlChar, f: xmlHashScannerFull, data: ?*anyopaque) void;
pub const XML_ERR_NONE: c_int = 0;
pub const XML_ERR_WARNING: c_int = 1;
pub const XML_ERR_ERROR: c_int = 2;
pub const XML_ERR_FATAL: c_int = 3;
pub const xmlErrorLevel = c_uint;
pub const XML_FROM_NONE: c_int = 0;
pub const XML_FROM_PARSER: c_int = 1;
pub const XML_FROM_TREE: c_int = 2;
pub const XML_FROM_NAMESPACE: c_int = 3;
pub const XML_FROM_DTD: c_int = 4;
pub const XML_FROM_HTML: c_int = 5;
pub const XML_FROM_MEMORY: c_int = 6;
pub const XML_FROM_OUTPUT: c_int = 7;
pub const XML_FROM_IO: c_int = 8;
pub const XML_FROM_FTP: c_int = 9;
pub const XML_FROM_HTTP: c_int = 10;
pub const XML_FROM_XINCLUDE: c_int = 11;
pub const XML_FROM_XPATH: c_int = 12;
pub const XML_FROM_XPOINTER: c_int = 13;
pub const XML_FROM_REGEXP: c_int = 14;
pub const XML_FROM_DATATYPE: c_int = 15;
pub const XML_FROM_SCHEMASP: c_int = 16;
pub const XML_FROM_SCHEMASV: c_int = 17;
pub const XML_FROM_RELAXNGP: c_int = 18;
pub const XML_FROM_RELAXNGV: c_int = 19;
pub const XML_FROM_CATALOG: c_int = 20;
pub const XML_FROM_C14N: c_int = 21;
pub const XML_FROM_XSLT: c_int = 22;
pub const XML_FROM_VALID: c_int = 23;
pub const XML_FROM_CHECK: c_int = 24;
pub const XML_FROM_WRITER: c_int = 25;
pub const XML_FROM_MODULE: c_int = 26;
pub const XML_FROM_I18N: c_int = 27;
pub const XML_FROM_SCHEMATRONV: c_int = 28;
pub const XML_FROM_BUFFER: c_int = 29;
pub const XML_FROM_URI: c_int = 30;
pub const xmlErrorDomain = c_uint;
pub const XML_ERR_OK: c_int = 0;
pub const XML_ERR_INTERNAL_ERROR: c_int = 1;
pub const XML_ERR_NO_MEMORY: c_int = 2;
pub const XML_ERR_DOCUMENT_START: c_int = 3;
pub const XML_ERR_DOCUMENT_EMPTY: c_int = 4;
pub const XML_ERR_DOCUMENT_END: c_int = 5;
pub const XML_ERR_INVALID_HEX_CHARREF: c_int = 6;
pub const XML_ERR_INVALID_DEC_CHARREF: c_int = 7;
pub const XML_ERR_INVALID_CHARREF: c_int = 8;
pub const XML_ERR_INVALID_CHAR: c_int = 9;
pub const XML_ERR_CHARREF_AT_EOF: c_int = 10;
pub const XML_ERR_CHARREF_IN_PROLOG: c_int = 11;
pub const XML_ERR_CHARREF_IN_EPILOG: c_int = 12;
pub const XML_ERR_CHARREF_IN_DTD: c_int = 13;
pub const XML_ERR_ENTITYREF_AT_EOF: c_int = 14;
pub const XML_ERR_ENTITYREF_IN_PROLOG: c_int = 15;
pub const XML_ERR_ENTITYREF_IN_EPILOG: c_int = 16;
pub const XML_ERR_ENTITYREF_IN_DTD: c_int = 17;
pub const XML_ERR_PEREF_AT_EOF: c_int = 18;
pub const XML_ERR_PEREF_IN_PROLOG: c_int = 19;
pub const XML_ERR_PEREF_IN_EPILOG: c_int = 20;
pub const XML_ERR_PEREF_IN_INT_SUBSET: c_int = 21;
pub const XML_ERR_ENTITYREF_NO_NAME: c_int = 22;
pub const XML_ERR_ENTITYREF_SEMICOL_MISSING: c_int = 23;
pub const XML_ERR_PEREF_NO_NAME: c_int = 24;
pub const XML_ERR_PEREF_SEMICOL_MISSING: c_int = 25;
pub const XML_ERR_UNDECLARED_ENTITY: c_int = 26;
pub const XML_WAR_UNDECLARED_ENTITY: c_int = 27;
pub const XML_ERR_UNPARSED_ENTITY: c_int = 28;
pub const XML_ERR_ENTITY_IS_EXTERNAL: c_int = 29;
pub const XML_ERR_ENTITY_IS_PARAMETER: c_int = 30;
pub const XML_ERR_UNKNOWN_ENCODING: c_int = 31;
pub const XML_ERR_UNSUPPORTED_ENCODING: c_int = 32;
pub const XML_ERR_STRING_NOT_STARTED: c_int = 33;
pub const XML_ERR_STRING_NOT_CLOSED: c_int = 34;
pub const XML_ERR_NS_DECL_ERROR: c_int = 35;
pub const XML_ERR_ENTITY_NOT_STARTED: c_int = 36;
pub const XML_ERR_ENTITY_NOT_FINISHED: c_int = 37;
pub const XML_ERR_LT_IN_ATTRIBUTE: c_int = 38;
pub const XML_ERR_ATTRIBUTE_NOT_STARTED: c_int = 39;
pub const XML_ERR_ATTRIBUTE_NOT_FINISHED: c_int = 40;
pub const XML_ERR_ATTRIBUTE_WITHOUT_VALUE: c_int = 41;
pub const XML_ERR_ATTRIBUTE_REDEFINED: c_int = 42;
pub const XML_ERR_LITERAL_NOT_STARTED: c_int = 43;
pub const XML_ERR_LITERAL_NOT_FINISHED: c_int = 44;
pub const XML_ERR_COMMENT_NOT_FINISHED: c_int = 45;
pub const XML_ERR_PI_NOT_STARTED: c_int = 46;
pub const XML_ERR_PI_NOT_FINISHED: c_int = 47;
pub const XML_ERR_NOTATION_NOT_STARTED: c_int = 48;
pub const XML_ERR_NOTATION_NOT_FINISHED: c_int = 49;
pub const XML_ERR_ATTLIST_NOT_STARTED: c_int = 50;
pub const XML_ERR_ATTLIST_NOT_FINISHED: c_int = 51;
pub const XML_ERR_MIXED_NOT_STARTED: c_int = 52;
pub const XML_ERR_MIXED_NOT_FINISHED: c_int = 53;
pub const XML_ERR_ELEMCONTENT_NOT_STARTED: c_int = 54;
pub const XML_ERR_ELEMCONTENT_NOT_FINISHED: c_int = 55;
pub const XML_ERR_XMLDECL_NOT_STARTED: c_int = 56;
pub const XML_ERR_XMLDECL_NOT_FINISHED: c_int = 57;
pub const XML_ERR_CONDSEC_NOT_STARTED: c_int = 58;
pub const XML_ERR_CONDSEC_NOT_FINISHED: c_int = 59;
pub const XML_ERR_EXT_SUBSET_NOT_FINISHED: c_int = 60;
pub const XML_ERR_DOCTYPE_NOT_FINISHED: c_int = 61;
pub const XML_ERR_MISPLACED_CDATA_END: c_int = 62;
pub const XML_ERR_CDATA_NOT_FINISHED: c_int = 63;
pub const XML_ERR_RESERVED_XML_NAME: c_int = 64;
pub const XML_ERR_SPACE_REQUIRED: c_int = 65;
pub const XML_ERR_SEPARATOR_REQUIRED: c_int = 66;
pub const XML_ERR_NMTOKEN_REQUIRED: c_int = 67;
pub const XML_ERR_NAME_REQUIRED: c_int = 68;
pub const XML_ERR_PCDATA_REQUIRED: c_int = 69;
pub const XML_ERR_URI_REQUIRED: c_int = 70;
pub const XML_ERR_PUBID_REQUIRED: c_int = 71;
pub const XML_ERR_LT_REQUIRED: c_int = 72;
pub const XML_ERR_GT_REQUIRED: c_int = 73;
pub const XML_ERR_LTSLASH_REQUIRED: c_int = 74;
pub const XML_ERR_EQUAL_REQUIRED: c_int = 75;
pub const XML_ERR_TAG_NAME_MISMATCH: c_int = 76;
pub const XML_ERR_TAG_NOT_FINISHED: c_int = 77;
pub const XML_ERR_STANDALONE_VALUE: c_int = 78;
pub const XML_ERR_ENCODING_NAME: c_int = 79;
pub const XML_ERR_HYPHEN_IN_COMMENT: c_int = 80;
pub const XML_ERR_INVALID_ENCODING: c_int = 81;
pub const XML_ERR_EXT_ENTITY_STANDALONE: c_int = 82;
pub const XML_ERR_CONDSEC_INVALID: c_int = 83;
pub const XML_ERR_VALUE_REQUIRED: c_int = 84;
pub const XML_ERR_NOT_WELL_BALANCED: c_int = 85;
pub const XML_ERR_EXTRA_CONTENT: c_int = 86;
pub const XML_ERR_ENTITY_CHAR_ERROR: c_int = 87;
pub const XML_ERR_ENTITY_PE_INTERNAL: c_int = 88;
pub const XML_ERR_ENTITY_LOOP: c_int = 89;
pub const XML_ERR_ENTITY_BOUNDARY: c_int = 90;
pub const XML_ERR_INVALID_URI: c_int = 91;
pub const XML_ERR_URI_FRAGMENT: c_int = 92;
pub const XML_WAR_CATALOG_PI: c_int = 93;
pub const XML_ERR_NO_DTD: c_int = 94;
pub const XML_ERR_CONDSEC_INVALID_KEYWORD: c_int = 95;
pub const XML_ERR_VERSION_MISSING: c_int = 96;
pub const XML_WAR_UNKNOWN_VERSION: c_int = 97;
pub const XML_WAR_LANG_VALUE: c_int = 98;
pub const XML_WAR_NS_URI: c_int = 99;
pub const XML_WAR_NS_URI_RELATIVE: c_int = 100;
pub const XML_ERR_MISSING_ENCODING: c_int = 101;
pub const XML_WAR_SPACE_VALUE: c_int = 102;
pub const XML_ERR_NOT_STANDALONE: c_int = 103;
pub const XML_ERR_ENTITY_PROCESSING: c_int = 104;
pub const XML_ERR_NOTATION_PROCESSING: c_int = 105;
pub const XML_WAR_NS_COLUMN: c_int = 106;
pub const XML_WAR_ENTITY_REDEFINED: c_int = 107;
pub const XML_ERR_UNKNOWN_VERSION: c_int = 108;
pub const XML_ERR_VERSION_MISMATCH: c_int = 109;
pub const XML_ERR_NAME_TOO_LONG: c_int = 110;
pub const XML_ERR_USER_STOP: c_int = 111;
pub const XML_ERR_COMMENT_ABRUPTLY_ENDED: c_int = 112;
pub const XML_NS_ERR_XML_NAMESPACE: c_int = 200;
pub const XML_NS_ERR_UNDEFINED_NAMESPACE: c_int = 201;
pub const XML_NS_ERR_QNAME: c_int = 202;
pub const XML_NS_ERR_ATTRIBUTE_REDEFINED: c_int = 203;
pub const XML_NS_ERR_EMPTY: c_int = 204;
pub const XML_NS_ERR_COLON: c_int = 205;
pub const XML_DTD_ATTRIBUTE_DEFAULT: c_int = 500;
pub const XML_DTD_ATTRIBUTE_REDEFINED: c_int = 501;
pub const XML_DTD_ATTRIBUTE_VALUE: c_int = 502;
pub const XML_DTD_CONTENT_ERROR: c_int = 503;
pub const XML_DTD_CONTENT_MODEL: c_int = 504;
pub const XML_DTD_CONTENT_NOT_DETERMINIST: c_int = 505;
pub const XML_DTD_DIFFERENT_PREFIX: c_int = 506;
pub const XML_DTD_ELEM_DEFAULT_NAMESPACE: c_int = 507;
pub const XML_DTD_ELEM_NAMESPACE: c_int = 508;
pub const XML_DTD_ELEM_REDEFINED: c_int = 509;
pub const XML_DTD_EMPTY_NOTATION: c_int = 510;
pub const XML_DTD_ENTITY_TYPE: c_int = 511;
pub const XML_DTD_ID_FIXED: c_int = 512;
pub const XML_DTD_ID_REDEFINED: c_int = 513;
pub const XML_DTD_ID_SUBSET: c_int = 514;
pub const XML_DTD_INVALID_CHILD: c_int = 515;
pub const XML_DTD_INVALID_DEFAULT: c_int = 516;
pub const XML_DTD_LOAD_ERROR: c_int = 517;
pub const XML_DTD_MISSING_ATTRIBUTE: c_int = 518;
pub const XML_DTD_MIXED_CORRUPT: c_int = 519;
pub const XML_DTD_MULTIPLE_ID: c_int = 520;
pub const XML_DTD_NO_DOC: c_int = 521;
pub const XML_DTD_NO_DTD: c_int = 522;
pub const XML_DTD_NO_ELEM_NAME: c_int = 523;
pub const XML_DTD_NO_PREFIX: c_int = 524;
pub const XML_DTD_NO_ROOT: c_int = 525;
pub const XML_DTD_NOTATION_REDEFINED: c_int = 526;
pub const XML_DTD_NOTATION_VALUE: c_int = 527;
pub const XML_DTD_NOT_EMPTY: c_int = 528;
pub const XML_DTD_NOT_PCDATA: c_int = 529;
pub const XML_DTD_NOT_STANDALONE: c_int = 530;
pub const XML_DTD_ROOT_NAME: c_int = 531;
pub const XML_DTD_STANDALONE_WHITE_SPACE: c_int = 532;
pub const XML_DTD_UNKNOWN_ATTRIBUTE: c_int = 533;
pub const XML_DTD_UNKNOWN_ELEM: c_int = 534;
pub const XML_DTD_UNKNOWN_ENTITY: c_int = 535;
pub const XML_DTD_UNKNOWN_ID: c_int = 536;
pub const XML_DTD_UNKNOWN_NOTATION: c_int = 537;
pub const XML_DTD_STANDALONE_DEFAULTED: c_int = 538;
pub const XML_DTD_XMLID_VALUE: c_int = 539;
pub const XML_DTD_XMLID_TYPE: c_int = 540;
pub const XML_DTD_DUP_TOKEN: c_int = 541;
pub const XML_HTML_STRUCURE_ERROR: c_int = 800;
pub const XML_HTML_UNKNOWN_TAG: c_int = 801;
pub const XML_HTML_INCORRECTLY_OPENED_COMMENT: c_int = 802;
pub const XML_RNGP_ANYNAME_ATTR_ANCESTOR: c_int = 1000;
pub const XML_RNGP_ATTR_CONFLICT: c_int = 1001;
pub const XML_RNGP_ATTRIBUTE_CHILDREN: c_int = 1002;
pub const XML_RNGP_ATTRIBUTE_CONTENT: c_int = 1003;
pub const XML_RNGP_ATTRIBUTE_EMPTY: c_int = 1004;
pub const XML_RNGP_ATTRIBUTE_NOOP: c_int = 1005;
pub const XML_RNGP_CHOICE_CONTENT: c_int = 1006;
pub const XML_RNGP_CHOICE_EMPTY: c_int = 1007;
pub const XML_RNGP_CREATE_FAILURE: c_int = 1008;
pub const XML_RNGP_DATA_CONTENT: c_int = 1009;
pub const XML_RNGP_DEF_CHOICE_AND_INTERLEAVE: c_int = 1010;
pub const XML_RNGP_DEFINE_CREATE_FAILED: c_int = 1011;
pub const XML_RNGP_DEFINE_EMPTY: c_int = 1012;
pub const XML_RNGP_DEFINE_MISSING: c_int = 1013;
pub const XML_RNGP_DEFINE_NAME_MISSING: c_int = 1014;
pub const XML_RNGP_ELEM_CONTENT_EMPTY: c_int = 1015;
pub const XML_RNGP_ELEM_CONTENT_ERROR: c_int = 1016;
pub const XML_RNGP_ELEMENT_EMPTY: c_int = 1017;
pub const XML_RNGP_ELEMENT_CONTENT: c_int = 1018;
pub const XML_RNGP_ELEMENT_NAME: c_int = 1019;
pub const XML_RNGP_ELEMENT_NO_CONTENT: c_int = 1020;
pub const XML_RNGP_ELEM_TEXT_CONFLICT: c_int = 1021;
pub const XML_RNGP_EMPTY: c_int = 1022;
pub const XML_RNGP_EMPTY_CONSTRUCT: c_int = 1023;
pub const XML_RNGP_EMPTY_CONTENT: c_int = 1024;
pub const XML_RNGP_EMPTY_NOT_EMPTY: c_int = 1025;
pub const XML_RNGP_ERROR_TYPE_LIB: c_int = 1026;
pub const XML_RNGP_EXCEPT_EMPTY: c_int = 1027;
pub const XML_RNGP_EXCEPT_MISSING: c_int = 1028;
pub const XML_RNGP_EXCEPT_MULTIPLE: c_int = 1029;
pub const XML_RNGP_EXCEPT_NO_CONTENT: c_int = 1030;
pub const XML_RNGP_EXTERNALREF_EMTPY: c_int = 1031;
pub const XML_RNGP_EXTERNAL_REF_FAILURE: c_int = 1032;
pub const XML_RNGP_EXTERNALREF_RECURSE: c_int = 1033;
pub const XML_RNGP_FORBIDDEN_ATTRIBUTE: c_int = 1034;
pub const XML_RNGP_FOREIGN_ELEMENT: c_int = 1035;
pub const XML_RNGP_GRAMMAR_CONTENT: c_int = 1036;
pub const XML_RNGP_GRAMMAR_EMPTY: c_int = 1037;
pub const XML_RNGP_GRAMMAR_MISSING: c_int = 1038;
pub const XML_RNGP_GRAMMAR_NO_START: c_int = 1039;
pub const XML_RNGP_GROUP_ATTR_CONFLICT: c_int = 1040;
pub const XML_RNGP_HREF_ERROR: c_int = 1041;
pub const XML_RNGP_INCLUDE_EMPTY: c_int = 1042;
pub const XML_RNGP_INCLUDE_FAILURE: c_int = 1043;
pub const XML_RNGP_INCLUDE_RECURSE: c_int = 1044;
pub const XML_RNGP_INTERLEAVE_ADD: c_int = 1045;
pub const XML_RNGP_INTERLEAVE_CREATE_FAILED: c_int = 1046;
pub const XML_RNGP_INTERLEAVE_EMPTY: c_int = 1047;
pub const XML_RNGP_INTERLEAVE_NO_CONTENT: c_int = 1048;
pub const XML_RNGP_INVALID_DEFINE_NAME: c_int = 1049;
pub const XML_RNGP_INVALID_URI: c_int = 1050;
pub const XML_RNGP_INVALID_VALUE: c_int = 1051;
pub const XML_RNGP_MISSING_HREF: c_int = 1052;
pub const XML_RNGP_NAME_MISSING: c_int = 1053;
pub const XML_RNGP_NEED_COMBINE: c_int = 1054;
pub const XML_RNGP_NOTALLOWED_NOT_EMPTY: c_int = 1055;
pub const XML_RNGP_NSNAME_ATTR_ANCESTOR: c_int = 1056;
pub const XML_RNGP_NSNAME_NO_NS: c_int = 1057;
pub const XML_RNGP_PARAM_FORBIDDEN: c_int = 1058;
pub const XML_RNGP_PARAM_NAME_MISSING: c_int = 1059;
pub const XML_RNGP_PARENTREF_CREATE_FAILED: c_int = 1060;
pub const XML_RNGP_PARENTREF_NAME_INVALID: c_int = 1061;
pub const XML_RNGP_PARENTREF_NO_NAME: c_int = 1062;
pub const XML_RNGP_PARENTREF_NO_PARENT: c_int = 1063;
pub const XML_RNGP_PARENTREF_NOT_EMPTY: c_int = 1064;
pub const XML_RNGP_PARSE_ERROR: c_int = 1065;
pub const XML_RNGP_PAT_ANYNAME_EXCEPT_ANYNAME: c_int = 1066;
pub const XML_RNGP_PAT_ATTR_ATTR: c_int = 1067;
pub const XML_RNGP_PAT_ATTR_ELEM: c_int = 1068;
pub const XML_RNGP_PAT_DATA_EXCEPT_ATTR: c_int = 1069;
pub const XML_RNGP_PAT_DATA_EXCEPT_ELEM: c_int = 1070;
pub const XML_RNGP_PAT_DATA_EXCEPT_EMPTY: c_int = 1071;
pub const XML_RNGP_PAT_DATA_EXCEPT_GROUP: c_int = 1072;
pub const XML_RNGP_PAT_DATA_EXCEPT_INTERLEAVE: c_int = 1073;
pub const XML_RNGP_PAT_DATA_EXCEPT_LIST: c_int = 1074;
pub const XML_RNGP_PAT_DATA_EXCEPT_ONEMORE: c_int = 1075;
pub const XML_RNGP_PAT_DATA_EXCEPT_REF: c_int = 1076;
pub const XML_RNGP_PAT_DATA_EXCEPT_TEXT: c_int = 1077;
pub const XML_RNGP_PAT_LIST_ATTR: c_int = 1078;
pub const XML_RNGP_PAT_LIST_ELEM: c_int = 1079;
pub const XML_RNGP_PAT_LIST_INTERLEAVE: c_int = 1080;
pub const XML_RNGP_PAT_LIST_LIST: c_int = 1081;
pub const XML_RNGP_PAT_LIST_REF: c_int = 1082;
pub const XML_RNGP_PAT_LIST_TEXT: c_int = 1083;
pub const XML_RNGP_PAT_NSNAME_EXCEPT_ANYNAME: c_int = 1084;
pub const XML_RNGP_PAT_NSNAME_EXCEPT_NSNAME: c_int = 1085;
pub const XML_RNGP_PAT_ONEMORE_GROUP_ATTR: c_int = 1086;
pub const XML_RNGP_PAT_ONEMORE_INTERLEAVE_ATTR: c_int = 1087;
pub const XML_RNGP_PAT_START_ATTR: c_int = 1088;
pub const XML_RNGP_PAT_START_DATA: c_int = 1089;
pub const XML_RNGP_PAT_START_EMPTY: c_int = 1090;
pub const XML_RNGP_PAT_START_GROUP: c_int = 1091;
pub const XML_RNGP_PAT_START_INTERLEAVE: c_int = 1092;
pub const XML_RNGP_PAT_START_LIST: c_int = 1093;
pub const XML_RNGP_PAT_START_ONEMORE: c_int = 1094;
pub const XML_RNGP_PAT_START_TEXT: c_int = 1095;
pub const XML_RNGP_PAT_START_VALUE: c_int = 1096;
pub const XML_RNGP_PREFIX_UNDEFINED: c_int = 1097;
pub const XML_RNGP_REF_CREATE_FAILED: c_int = 1098;
pub const XML_RNGP_REF_CYCLE: c_int = 1099;
pub const XML_RNGP_REF_NAME_INVALID: c_int = 1100;
pub const XML_RNGP_REF_NO_DEF: c_int = 1101;
pub const XML_RNGP_REF_NO_NAME: c_int = 1102;
pub const XML_RNGP_REF_NOT_EMPTY: c_int = 1103;
pub const XML_RNGP_START_CHOICE_AND_INTERLEAVE: c_int = 1104;
pub const XML_RNGP_START_CONTENT: c_int = 1105;
pub const XML_RNGP_START_EMPTY: c_int = 1106;
pub const XML_RNGP_START_MISSING: c_int = 1107;
pub const XML_RNGP_TEXT_EXPECTED: c_int = 1108;
pub const XML_RNGP_TEXT_HAS_CHILD: c_int = 1109;
pub const XML_RNGP_TYPE_MISSING: c_int = 1110;
pub const XML_RNGP_TYPE_NOT_FOUND: c_int = 1111;
pub const XML_RNGP_TYPE_VALUE: c_int = 1112;
pub const XML_RNGP_UNKNOWN_ATTRIBUTE: c_int = 1113;
pub const XML_RNGP_UNKNOWN_COMBINE: c_int = 1114;
pub const XML_RNGP_UNKNOWN_CONSTRUCT: c_int = 1115;
pub const XML_RNGP_UNKNOWN_TYPE_LIB: c_int = 1116;
pub const XML_RNGP_URI_FRAGMENT: c_int = 1117;
pub const XML_RNGP_URI_NOT_ABSOLUTE: c_int = 1118;
pub const XML_RNGP_VALUE_EMPTY: c_int = 1119;
pub const XML_RNGP_VALUE_NO_CONTENT: c_int = 1120;
pub const XML_RNGP_XMLNS_NAME: c_int = 1121;
pub const XML_RNGP_XML_NS: c_int = 1122;
pub const XML_XPATH_EXPRESSION_OK: c_int = 1200;
pub const XML_XPATH_NUMBER_ERROR: c_int = 1201;
pub const XML_XPATH_UNFINISHED_LITERAL_ERROR: c_int = 1202;
pub const XML_XPATH_START_LITERAL_ERROR: c_int = 1203;
pub const XML_XPATH_VARIABLE_REF_ERROR: c_int = 1204;
pub const XML_XPATH_UNDEF_VARIABLE_ERROR: c_int = 1205;
pub const XML_XPATH_INVALID_PREDICATE_ERROR: c_int = 1206;
pub const XML_XPATH_EXPR_ERROR: c_int = 1207;
pub const XML_XPATH_UNCLOSED_ERROR: c_int = 1208;
pub const XML_XPATH_UNKNOWN_FUNC_ERROR: c_int = 1209;
pub const XML_XPATH_INVALID_OPERAND: c_int = 1210;
pub const XML_XPATH_INVALID_TYPE: c_int = 1211;
pub const XML_XPATH_INVALID_ARITY: c_int = 1212;
pub const XML_XPATH_INVALID_CTXT_SIZE: c_int = 1213;
pub const XML_XPATH_INVALID_CTXT_POSITION: c_int = 1214;
pub const XML_XPATH_MEMORY_ERROR: c_int = 1215;
pub const XML_XPTR_SYNTAX_ERROR: c_int = 1216;
pub const XML_XPTR_RESOURCE_ERROR: c_int = 1217;
pub const XML_XPTR_SUB_RESOURCE_ERROR: c_int = 1218;
pub const XML_XPATH_UNDEF_PREFIX_ERROR: c_int = 1219;
pub const XML_XPATH_ENCODING_ERROR: c_int = 1220;
pub const XML_XPATH_INVALID_CHAR_ERROR: c_int = 1221;
pub const XML_TREE_INVALID_HEX: c_int = 1300;
pub const XML_TREE_INVALID_DEC: c_int = 1301;
pub const XML_TREE_UNTERMINATED_ENTITY: c_int = 1302;
pub const XML_TREE_NOT_UTF8: c_int = 1303;
pub const XML_SAVE_NOT_UTF8: c_int = 1400;
pub const XML_SAVE_CHAR_INVALID: c_int = 1401;
pub const XML_SAVE_NO_DOCTYPE: c_int = 1402;
pub const XML_SAVE_UNKNOWN_ENCODING: c_int = 1403;
pub const XML_REGEXP_COMPILE_ERROR: c_int = 1450;
pub const XML_IO_UNKNOWN: c_int = 1500;
pub const XML_IO_EACCES: c_int = 1501;
pub const XML_IO_EAGAIN: c_int = 1502;
pub const XML_IO_EBADF: c_int = 1503;
pub const XML_IO_EBADMSG: c_int = 1504;
pub const XML_IO_EBUSY: c_int = 1505;
pub const XML_IO_ECANCELED: c_int = 1506;
pub const XML_IO_ECHILD: c_int = 1507;
pub const XML_IO_EDEADLK: c_int = 1508;
pub const XML_IO_EDOM: c_int = 1509;
pub const XML_IO_EEXIST: c_int = 1510;
pub const XML_IO_EFAULT: c_int = 1511;
pub const XML_IO_EFBIG: c_int = 1512;
pub const XML_IO_EINPROGRESS: c_int = 1513;
pub const XML_IO_EINTR: c_int = 1514;
pub const XML_IO_EINVAL: c_int = 1515;
pub const XML_IO_EIO: c_int = 1516;
pub const XML_IO_EISDIR: c_int = 1517;
pub const XML_IO_EMFILE: c_int = 1518;
pub const XML_IO_EMLINK: c_int = 1519;
pub const XML_IO_EMSGSIZE: c_int = 1520;
pub const XML_IO_ENAMETOOLONG: c_int = 1521;
pub const XML_IO_ENFILE: c_int = 1522;
pub const XML_IO_ENODEV: c_int = 1523;
pub const XML_IO_ENOENT: c_int = 1524;
pub const XML_IO_ENOEXEC: c_int = 1525;
pub const XML_IO_ENOLCK: c_int = 1526;
pub const XML_IO_ENOMEM: c_int = 1527;
pub const XML_IO_ENOSPC: c_int = 1528;
pub const XML_IO_ENOSYS: c_int = 1529;
pub const XML_IO_ENOTDIR: c_int = 1530;
pub const XML_IO_ENOTEMPTY: c_int = 1531;
pub const XML_IO_ENOTSUP: c_int = 1532;
pub const XML_IO_ENOTTY: c_int = 1533;
pub const XML_IO_ENXIO: c_int = 1534;
pub const XML_IO_EPERM: c_int = 1535;
pub const XML_IO_EPIPE: c_int = 1536;
pub const XML_IO_ERANGE: c_int = 1537;
pub const XML_IO_EROFS: c_int = 1538;
pub const XML_IO_ESPIPE: c_int = 1539;
pub const XML_IO_ESRCH: c_int = 1540;
pub const XML_IO_ETIMEDOUT: c_int = 1541;
pub const XML_IO_EXDEV: c_int = 1542;
pub const XML_IO_NETWORK_ATTEMPT: c_int = 1543;
pub const XML_IO_ENCODER: c_int = 1544;
pub const XML_IO_FLUSH: c_int = 1545;
pub const XML_IO_WRITE: c_int = 1546;
pub const XML_IO_NO_INPUT: c_int = 1547;
pub const XML_IO_BUFFER_FULL: c_int = 1548;
pub const XML_IO_LOAD_ERROR: c_int = 1549;
pub const XML_IO_ENOTSOCK: c_int = 1550;
pub const XML_IO_EISCONN: c_int = 1551;
pub const XML_IO_ECONNREFUSED: c_int = 1552;
pub const XML_IO_ENETUNREACH: c_int = 1553;
pub const XML_IO_EADDRINUSE: c_int = 1554;
pub const XML_IO_EALREADY: c_int = 1555;
pub const XML_IO_EAFNOSUPPORT: c_int = 1556;
pub const XML_XINCLUDE_RECURSION: c_int = 1600;
pub const XML_XINCLUDE_PARSE_VALUE: c_int = 1601;
pub const XML_XINCLUDE_ENTITY_DEF_MISMATCH: c_int = 1602;
pub const XML_XINCLUDE_NO_HREF: c_int = 1603;
pub const XML_XINCLUDE_NO_FALLBACK: c_int = 1604;
pub const XML_XINCLUDE_HREF_URI: c_int = 1605;
pub const XML_XINCLUDE_TEXT_FRAGMENT: c_int = 1606;
pub const XML_XINCLUDE_TEXT_DOCUMENT: c_int = 1607;
pub const XML_XINCLUDE_INVALID_CHAR: c_int = 1608;
pub const XML_XINCLUDE_BUILD_FAILED: c_int = 1609;
pub const XML_XINCLUDE_UNKNOWN_ENCODING: c_int = 1610;
pub const XML_XINCLUDE_MULTIPLE_ROOT: c_int = 1611;
pub const XML_XINCLUDE_XPTR_FAILED: c_int = 1612;
pub const XML_XINCLUDE_XPTR_RESULT: c_int = 1613;
pub const XML_XINCLUDE_INCLUDE_IN_INCLUDE: c_int = 1614;
pub const XML_XINCLUDE_FALLBACKS_IN_INCLUDE: c_int = 1615;
pub const XML_XINCLUDE_FALLBACK_NOT_IN_INCLUDE: c_int = 1616;
pub const XML_XINCLUDE_DEPRECATED_NS: c_int = 1617;
pub const XML_XINCLUDE_FRAGMENT_ID: c_int = 1618;
pub const XML_CATALOG_MISSING_ATTR: c_int = 1650;
pub const XML_CATALOG_ENTRY_BROKEN: c_int = 1651;
pub const XML_CATALOG_PREFER_VALUE: c_int = 1652;
pub const XML_CATALOG_NOT_CATALOG: c_int = 1653;
pub const XML_CATALOG_RECURSION: c_int = 1654;
pub const XML_SCHEMAP_PREFIX_UNDEFINED: c_int = 1700;
pub const XML_SCHEMAP_ATTRFORMDEFAULT_VALUE: c_int = 1701;
pub const XML_SCHEMAP_ATTRGRP_NONAME_NOREF: c_int = 1702;
pub const XML_SCHEMAP_ATTR_NONAME_NOREF: c_int = 1703;
pub const XML_SCHEMAP_COMPLEXTYPE_NONAME_NOREF: c_int = 1704;
pub const XML_SCHEMAP_ELEMFORMDEFAULT_VALUE: c_int = 1705;
pub const XML_SCHEMAP_ELEM_NONAME_NOREF: c_int = 1706;
pub const XML_SCHEMAP_EXTENSION_NO_BASE: c_int = 1707;
pub const XML_SCHEMAP_FACET_NO_VALUE: c_int = 1708;
pub const XML_SCHEMAP_FAILED_BUILD_IMPORT: c_int = 1709;
pub const XML_SCHEMAP_GROUP_NONAME_NOREF: c_int = 1710;
pub const XML_SCHEMAP_IMPORT_NAMESPACE_NOT_URI: c_int = 1711;
pub const XML_SCHEMAP_IMPORT_REDEFINE_NSNAME: c_int = 1712;
pub const XML_SCHEMAP_IMPORT_SCHEMA_NOT_URI: c_int = 1713;
pub const XML_SCHEMAP_INVALID_BOOLEAN: c_int = 1714;
pub const XML_SCHEMAP_INVALID_ENUM: c_int = 1715;
pub const XML_SCHEMAP_INVALID_FACET: c_int = 1716;
pub const XML_SCHEMAP_INVALID_FACET_VALUE: c_int = 1717;
pub const XML_SCHEMAP_INVALID_MAXOCCURS: c_int = 1718;
pub const XML_SCHEMAP_INVALID_MINOCCURS: c_int = 1719;
pub const XML_SCHEMAP_INVALID_REF_AND_SUBTYPE: c_int = 1720;
pub const XML_SCHEMAP_INVALID_WHITE_SPACE: c_int = 1721;
pub const XML_SCHEMAP_NOATTR_NOREF: c_int = 1722;
pub const XML_SCHEMAP_NOTATION_NO_NAME: c_int = 1723;
pub const XML_SCHEMAP_NOTYPE_NOREF: c_int = 1724;
pub const XML_SCHEMAP_REF_AND_SUBTYPE: c_int = 1725;
pub const XML_SCHEMAP_RESTRICTION_NONAME_NOREF: c_int = 1726;
pub const XML_SCHEMAP_SIMPLETYPE_NONAME: c_int = 1727;
pub const XML_SCHEMAP_TYPE_AND_SUBTYPE: c_int = 1728;
pub const XML_SCHEMAP_UNKNOWN_ALL_CHILD: c_int = 1729;
pub const XML_SCHEMAP_UNKNOWN_ANYATTRIBUTE_CHILD: c_int = 1730;
pub const XML_SCHEMAP_UNKNOWN_ATTR_CHILD: c_int = 1731;
pub const XML_SCHEMAP_UNKNOWN_ATTRGRP_CHILD: c_int = 1732;
pub const XML_SCHEMAP_UNKNOWN_ATTRIBUTE_GROUP: c_int = 1733;
pub const XML_SCHEMAP_UNKNOWN_BASE_TYPE: c_int = 1734;
pub const XML_SCHEMAP_UNKNOWN_CHOICE_CHILD: c_int = 1735;
pub const XML_SCHEMAP_UNKNOWN_COMPLEXCONTENT_CHILD: c_int = 1736;
pub const XML_SCHEMAP_UNKNOWN_COMPLEXTYPE_CHILD: c_int = 1737;
pub const XML_SCHEMAP_UNKNOWN_ELEM_CHILD: c_int = 1738;
pub const XML_SCHEMAP_UNKNOWN_EXTENSION_CHILD: c_int = 1739;
pub const XML_SCHEMAP_UNKNOWN_FACET_CHILD: c_int = 1740;
pub const XML_SCHEMAP_UNKNOWN_FACET_TYPE: c_int = 1741;
pub const XML_SCHEMAP_UNKNOWN_GROUP_CHILD: c_int = 1742;
pub const XML_SCHEMAP_UNKNOWN_IMPORT_CHILD: c_int = 1743;
pub const XML_SCHEMAP_UNKNOWN_LIST_CHILD: c_int = 1744;
pub const XML_SCHEMAP_UNKNOWN_NOTATION_CHILD: c_int = 1745;
pub const XML_SCHEMAP_UNKNOWN_PROCESSCONTENT_CHILD: c_int = 1746;
pub const XML_SCHEMAP_UNKNOWN_REF: c_int = 1747;
pub const XML_SCHEMAP_UNKNOWN_RESTRICTION_CHILD: c_int = 1748;
pub const XML_SCHEMAP_UNKNOWN_SCHEMAS_CHILD: c_int = 1749;
pub const XML_SCHEMAP_UNKNOWN_SEQUENCE_CHILD: c_int = 1750;
pub const XML_SCHEMAP_UNKNOWN_SIMPLECONTENT_CHILD: c_int = 1751;
pub const XML_SCHEMAP_UNKNOWN_SIMPLETYPE_CHILD: c_int = 1752;
pub const XML_SCHEMAP_UNKNOWN_TYPE: c_int = 1753;
pub const XML_SCHEMAP_UNKNOWN_UNION_CHILD: c_int = 1754;
pub const XML_SCHEMAP_ELEM_DEFAULT_FIXED: c_int = 1755;
pub const XML_SCHEMAP_REGEXP_INVALID: c_int = 1756;
pub const XML_SCHEMAP_FAILED_LOAD: c_int = 1757;
pub const XML_SCHEMAP_NOTHING_TO_PARSE: c_int = 1758;
pub const XML_SCHEMAP_NOROOT: c_int = 1759;
pub const XML_SCHEMAP_REDEFINED_GROUP: c_int = 1760;
pub const XML_SCHEMAP_REDEFINED_TYPE: c_int = 1761;
pub const XML_SCHEMAP_REDEFINED_ELEMENT: c_int = 1762;
pub const XML_SCHEMAP_REDEFINED_ATTRGROUP: c_int = 1763;
pub const XML_SCHEMAP_REDEFINED_ATTR: c_int = 1764;
pub const XML_SCHEMAP_REDEFINED_NOTATION: c_int = 1765;
pub const XML_SCHEMAP_FAILED_PARSE: c_int = 1766;
pub const XML_SCHEMAP_UNKNOWN_PREFIX: c_int = 1767;
pub const XML_SCHEMAP_DEF_AND_PREFIX: c_int = 1768;
pub const XML_SCHEMAP_UNKNOWN_INCLUDE_CHILD: c_int = 1769;
pub const XML_SCHEMAP_INCLUDE_SCHEMA_NOT_URI: c_int = 1770;
pub const XML_SCHEMAP_INCLUDE_SCHEMA_NO_URI: c_int = 1771;
pub const XML_SCHEMAP_NOT_SCHEMA: c_int = 1772;
pub const XML_SCHEMAP_UNKNOWN_MEMBER_TYPE: c_int = 1773;
pub const XML_SCHEMAP_INVALID_ATTR_USE: c_int = 1774;
pub const XML_SCHEMAP_RECURSIVE: c_int = 1775;
pub const XML_SCHEMAP_SUPERNUMEROUS_LIST_ITEM_TYPE: c_int = 1776;
pub const XML_SCHEMAP_INVALID_ATTR_COMBINATION: c_int = 1777;
pub const XML_SCHEMAP_INVALID_ATTR_INLINE_COMBINATION: c_int = 1778;
pub const XML_SCHEMAP_MISSING_SIMPLETYPE_CHILD: c_int = 1779;
pub const XML_SCHEMAP_INVALID_ATTR_NAME: c_int = 1780;
pub const XML_SCHEMAP_REF_AND_CONTENT: c_int = 1781;
pub const XML_SCHEMAP_CT_PROPS_CORRECT_1: c_int = 1782;
pub const XML_SCHEMAP_CT_PROPS_CORRECT_2: c_int = 1783;
pub const XML_SCHEMAP_CT_PROPS_CORRECT_3: c_int = 1784;
pub const XML_SCHEMAP_CT_PROPS_CORRECT_4: c_int = 1785;
pub const XML_SCHEMAP_CT_PROPS_CORRECT_5: c_int = 1786;
pub const XML_SCHEMAP_DERIVATION_OK_RESTRICTION_1: c_int = 1787;
pub const XML_SCHEMAP_DERIVATION_OK_RESTRICTION_2_1_1: c_int = 1788;
pub const XML_SCHEMAP_DERIVATION_OK_RESTRICTION_2_1_2: c_int = 1789;
pub const XML_SCHEMAP_DERIVATION_OK_RESTRICTION_2_2: c_int = 1790;
pub const XML_SCHEMAP_DERIVATION_OK_RESTRICTION_3: c_int = 1791;
pub const XML_SCHEMAP_WILDCARD_INVALID_NS_MEMBER: c_int = 1792;
pub const XML_SCHEMAP_INTERSECTION_NOT_EXPRESSIBLE: c_int = 1793;
pub const XML_SCHEMAP_UNION_NOT_EXPRESSIBLE: c_int = 1794;
pub const XML_SCHEMAP_SRC_IMPORT_3_1: c_int = 1795;
pub const XML_SCHEMAP_SRC_IMPORT_3_2: c_int = 1796;
pub const XML_SCHEMAP_DERIVATION_OK_RESTRICTION_4_1: c_int = 1797;
pub const XML_SCHEMAP_DERIVATION_OK_RESTRICTION_4_2: c_int = 1798;
pub const XML_SCHEMAP_DERIVATION_OK_RESTRICTION_4_3: c_int = 1799;
pub const XML_SCHEMAP_COS_CT_EXTENDS_1_3: c_int = 1800;
pub const XML_SCHEMAV_NOROOT: c_int = 1801;
pub const XML_SCHEMAV_UNDECLAREDELEM: c_int = 1802;
pub const XML_SCHEMAV_NOTTOPLEVEL: c_int = 1803;
pub const XML_SCHEMAV_MISSING: c_int = 1804;
pub const XML_SCHEMAV_WRONGELEM: c_int = 1805;
pub const XML_SCHEMAV_NOTYPE: c_int = 1806;
pub const XML_SCHEMAV_NOROLLBACK: c_int = 1807;
pub const XML_SCHEMAV_ISABSTRACT: c_int = 1808;
pub const XML_SCHEMAV_NOTEMPTY: c_int = 1809;
pub const XML_SCHEMAV_ELEMCONT: c_int = 1810;
pub const XML_SCHEMAV_HAVEDEFAULT: c_int = 1811;
pub const XML_SCHEMAV_NOTNILLABLE: c_int = 1812;
pub const XML_SCHEMAV_EXTRACONTENT: c_int = 1813;
pub const XML_SCHEMAV_INVALIDATTR: c_int = 1814;
pub const XML_SCHEMAV_INVALIDELEM: c_int = 1815;
pub const XML_SCHEMAV_NOTDETERMINIST: c_int = 1816;
pub const XML_SCHEMAV_CONSTRUCT: c_int = 1817;
pub const XML_SCHEMAV_INTERNAL: c_int = 1818;
pub const XML_SCHEMAV_NOTSIMPLE: c_int = 1819;
pub const XML_SCHEMAV_ATTRUNKNOWN: c_int = 1820;
pub const XML_SCHEMAV_ATTRINVALID: c_int = 1821;
pub const XML_SCHEMAV_VALUE: c_int = 1822;
pub const XML_SCHEMAV_FACET: c_int = 1823;
pub const XML_SCHEMAV_CVC_DATATYPE_VALID_1_2_1: c_int = 1824;
pub const XML_SCHEMAV_CVC_DATATYPE_VALID_1_2_2: c_int = 1825;
pub const XML_SCHEMAV_CVC_DATATYPE_VALID_1_2_3: c_int = 1826;
pub const XML_SCHEMAV_CVC_TYPE_3_1_1: c_int = 1827;
pub const XML_SCHEMAV_CVC_TYPE_3_1_2: c_int = 1828;
pub const XML_SCHEMAV_CVC_FACET_VALID: c_int = 1829;
pub const XML_SCHEMAV_CVC_LENGTH_VALID: c_int = 1830;
pub const XML_SCHEMAV_CVC_MINLENGTH_VALID: c_int = 1831;
pub const XML_SCHEMAV_CVC_MAXLENGTH_VALID: c_int = 1832;
pub const XML_SCHEMAV_CVC_MININCLUSIVE_VALID: c_int = 1833;
pub const XML_SCHEMAV_CVC_MAXINCLUSIVE_VALID: c_int = 1834;
pub const XML_SCHEMAV_CVC_MINEXCLUSIVE_VALID: c_int = 1835;
pub const XML_SCHEMAV_CVC_MAXEXCLUSIVE_VALID: c_int = 1836;
pub const XML_SCHEMAV_CVC_TOTALDIGITS_VALID: c_int = 1837;
pub const XML_SCHEMAV_CVC_FRACTIONDIGITS_VALID: c_int = 1838;
pub const XML_SCHEMAV_CVC_PATTERN_VALID: c_int = 1839;
pub const XML_SCHEMAV_CVC_ENUMERATION_VALID: c_int = 1840;
pub const XML_SCHEMAV_CVC_COMPLEX_TYPE_2_1: c_int = 1841;
pub const XML_SCHEMAV_CVC_COMPLEX_TYPE_2_2: c_int = 1842;
pub const XML_SCHEMAV_CVC_COMPLEX_TYPE_2_3: c_int = 1843;
pub const XML_SCHEMAV_CVC_COMPLEX_TYPE_2_4: c_int = 1844;
pub const XML_SCHEMAV_CVC_ELT_1: c_int = 1845;
pub const XML_SCHEMAV_CVC_ELT_2: c_int = 1846;
pub const XML_SCHEMAV_CVC_ELT_3_1: c_int = 1847;
pub const XML_SCHEMAV_CVC_ELT_3_2_1: c_int = 1848;
pub const XML_SCHEMAV_CVC_ELT_3_2_2: c_int = 1849;
pub const XML_SCHEMAV_CVC_ELT_4_1: c_int = 1850;
pub const XML_SCHEMAV_CVC_ELT_4_2: c_int = 1851;
pub const XML_SCHEMAV_CVC_ELT_4_3: c_int = 1852;
pub const XML_SCHEMAV_CVC_ELT_5_1_1: c_int = 1853;
pub const XML_SCHEMAV_CVC_ELT_5_1_2: c_int = 1854;
pub const XML_SCHEMAV_CVC_ELT_5_2_1: c_int = 1855;
pub const XML_SCHEMAV_CVC_ELT_5_2_2_1: c_int = 1856;
pub const XML_SCHEMAV_CVC_ELT_5_2_2_2_1: c_int = 1857;
pub const XML_SCHEMAV_CVC_ELT_5_2_2_2_2: c_int = 1858;
pub const XML_SCHEMAV_CVC_ELT_6: c_int = 1859;
pub const XML_SCHEMAV_CVC_ELT_7: c_int = 1860;
pub const XML_SCHEMAV_CVC_ATTRIBUTE_1: c_int = 1861;
pub const XML_SCHEMAV_CVC_ATTRIBUTE_2: c_int = 1862;
pub const XML_SCHEMAV_CVC_ATTRIBUTE_3: c_int = 1863;
pub const XML_SCHEMAV_CVC_ATTRIBUTE_4: c_int = 1864;
pub const XML_SCHEMAV_CVC_COMPLEX_TYPE_3_1: c_int = 1865;
pub const XML_SCHEMAV_CVC_COMPLEX_TYPE_3_2_1: c_int = 1866;
pub const XML_SCHEMAV_CVC_COMPLEX_TYPE_3_2_2: c_int = 1867;
pub const XML_SCHEMAV_CVC_COMPLEX_TYPE_4: c_int = 1868;
pub const XML_SCHEMAV_CVC_COMPLEX_TYPE_5_1: c_int = 1869;
pub const XML_SCHEMAV_CVC_COMPLEX_TYPE_5_2: c_int = 1870;
pub const XML_SCHEMAV_ELEMENT_CONTENT: c_int = 1871;
pub const XML_SCHEMAV_DOCUMENT_ELEMENT_MISSING: c_int = 1872;
pub const XML_SCHEMAV_CVC_COMPLEX_TYPE_1: c_int = 1873;
pub const XML_SCHEMAV_CVC_AU: c_int = 1874;
pub const XML_SCHEMAV_CVC_TYPE_1: c_int = 1875;
pub const XML_SCHEMAV_CVC_TYPE_2: c_int = 1876;
pub const XML_SCHEMAV_CVC_IDC: c_int = 1877;
pub const XML_SCHEMAV_CVC_WILDCARD: c_int = 1878;
pub const XML_SCHEMAV_MISC: c_int = 1879;
pub const XML_XPTR_UNKNOWN_SCHEME: c_int = 1900;
pub const XML_XPTR_CHILDSEQ_START: c_int = 1901;
pub const XML_XPTR_EVAL_FAILED: c_int = 1902;
pub const XML_XPTR_EXTRA_OBJECTS: c_int = 1903;
pub const XML_C14N_CREATE_CTXT: c_int = 1950;
pub const XML_C14N_REQUIRES_UTF8: c_int = 1951;
pub const XML_C14N_CREATE_STACK: c_int = 1952;
pub const XML_C14N_INVALID_NODE: c_int = 1953;
pub const XML_C14N_UNKNOW_NODE: c_int = 1954;
pub const XML_C14N_RELATIVE_NAMESPACE: c_int = 1955;
pub const XML_FTP_PASV_ANSWER: c_int = 2000;
pub const XML_FTP_EPSV_ANSWER: c_int = 2001;
pub const XML_FTP_ACCNT: c_int = 2002;
pub const XML_FTP_URL_SYNTAX: c_int = 2003;
pub const XML_HTTP_URL_SYNTAX: c_int = 2020;
pub const XML_HTTP_USE_IP: c_int = 2021;
pub const XML_HTTP_UNKNOWN_HOST: c_int = 2022;
pub const XML_SCHEMAP_SRC_SIMPLE_TYPE_1: c_int = 3000;
pub const XML_SCHEMAP_SRC_SIMPLE_TYPE_2: c_int = 3001;
pub const XML_SCHEMAP_SRC_SIMPLE_TYPE_3: c_int = 3002;
pub const XML_SCHEMAP_SRC_SIMPLE_TYPE_4: c_int = 3003;
pub const XML_SCHEMAP_SRC_RESOLVE: c_int = 3004;
pub const XML_SCHEMAP_SRC_RESTRICTION_BASE_OR_SIMPLETYPE: c_int = 3005;
pub const XML_SCHEMAP_SRC_LIST_ITEMTYPE_OR_SIMPLETYPE: c_int = 3006;
pub const XML_SCHEMAP_SRC_UNION_MEMBERTYPES_OR_SIMPLETYPES: c_int = 3007;
pub const XML_SCHEMAP_ST_PROPS_CORRECT_1: c_int = 3008;
pub const XML_SCHEMAP_ST_PROPS_CORRECT_2: c_int = 3009;
pub const XML_SCHEMAP_ST_PROPS_CORRECT_3: c_int = 3010;
pub const XML_SCHEMAP_COS_ST_RESTRICTS_1_1: c_int = 3011;
pub const XML_SCHEMAP_COS_ST_RESTRICTS_1_2: c_int = 3012;
pub const XML_SCHEMAP_COS_ST_RESTRICTS_1_3_1: c_int = 3013;
pub const XML_SCHEMAP_COS_ST_RESTRICTS_1_3_2: c_int = 3014;
pub const XML_SCHEMAP_COS_ST_RESTRICTS_2_1: c_int = 3015;
pub const XML_SCHEMAP_COS_ST_RESTRICTS_2_3_1_1: c_int = 3016;
pub const XML_SCHEMAP_COS_ST_RESTRICTS_2_3_1_2: c_int = 3017;
pub const XML_SCHEMAP_COS_ST_RESTRICTS_2_3_2_1: c_int = 3018;
pub const XML_SCHEMAP_COS_ST_RESTRICTS_2_3_2_2: c_int = 3019;
pub const XML_SCHEMAP_COS_ST_RESTRICTS_2_3_2_3: c_int = 3020;
pub const XML_SCHEMAP_COS_ST_RESTRICTS_2_3_2_4: c_int = 3021;
pub const XML_SCHEMAP_COS_ST_RESTRICTS_2_3_2_5: c_int = 3022;
pub const XML_SCHEMAP_COS_ST_RESTRICTS_3_1: c_int = 3023;
pub const XML_SCHEMAP_COS_ST_RESTRICTS_3_3_1: c_int = 3024;
pub const XML_SCHEMAP_COS_ST_RESTRICTS_3_3_1_2: c_int = 3025;
pub const XML_SCHEMAP_COS_ST_RESTRICTS_3_3_2_2: c_int = 3026;
pub const XML_SCHEMAP_COS_ST_RESTRICTS_3_3_2_1: c_int = 3027;
pub const XML_SCHEMAP_COS_ST_RESTRICTS_3_3_2_3: c_int = 3028;
pub const XML_SCHEMAP_COS_ST_RESTRICTS_3_3_2_4: c_int = 3029;
pub const XML_SCHEMAP_COS_ST_RESTRICTS_3_3_2_5: c_int = 3030;
pub const XML_SCHEMAP_COS_ST_DERIVED_OK_2_1: c_int = 3031;
pub const XML_SCHEMAP_COS_ST_DERIVED_OK_2_2: c_int = 3032;
pub const XML_SCHEMAP_S4S_ELEM_NOT_ALLOWED: c_int = 3033;
pub const XML_SCHEMAP_S4S_ELEM_MISSING: c_int = 3034;
pub const XML_SCHEMAP_S4S_ATTR_NOT_ALLOWED: c_int = 3035;
pub const XML_SCHEMAP_S4S_ATTR_MISSING: c_int = 3036;
pub const XML_SCHEMAP_S4S_ATTR_INVALID_VALUE: c_int = 3037;
pub const XML_SCHEMAP_SRC_ELEMENT_1: c_int = 3038;
pub const XML_SCHEMAP_SRC_ELEMENT_2_1: c_int = 3039;
pub const XML_SCHEMAP_SRC_ELEMENT_2_2: c_int = 3040;
pub const XML_SCHEMAP_SRC_ELEMENT_3: c_int = 3041;
pub const XML_SCHEMAP_P_PROPS_CORRECT_1: c_int = 3042;
pub const XML_SCHEMAP_P_PROPS_CORRECT_2_1: c_int = 3043;
pub const XML_SCHEMAP_P_PROPS_CORRECT_2_2: c_int = 3044;
pub const XML_SCHEMAP_E_PROPS_CORRECT_2: c_int = 3045;
pub const XML_SCHEMAP_E_PROPS_CORRECT_3: c_int = 3046;
pub const XML_SCHEMAP_E_PROPS_CORRECT_4: c_int = 3047;
pub const XML_SCHEMAP_E_PROPS_CORRECT_5: c_int = 3048;
pub const XML_SCHEMAP_E_PROPS_CORRECT_6: c_int = 3049;
pub const XML_SCHEMAP_SRC_INCLUDE: c_int = 3050;
pub const XML_SCHEMAP_SRC_ATTRIBUTE_1: c_int = 3051;
pub const XML_SCHEMAP_SRC_ATTRIBUTE_2: c_int = 3052;
pub const XML_SCHEMAP_SRC_ATTRIBUTE_3_1: c_int = 3053;
pub const XML_SCHEMAP_SRC_ATTRIBUTE_3_2: c_int = 3054;
pub const XML_SCHEMAP_SRC_ATTRIBUTE_4: c_int = 3055;
pub const XML_SCHEMAP_NO_XMLNS: c_int = 3056;
pub const XML_SCHEMAP_NO_XSI: c_int = 3057;
pub const XML_SCHEMAP_COS_VALID_DEFAULT_1: c_int = 3058;
pub const XML_SCHEMAP_COS_VALID_DEFAULT_2_1: c_int = 3059;
pub const XML_SCHEMAP_COS_VALID_DEFAULT_2_2_1: c_int = 3060;
pub const XML_SCHEMAP_COS_VALID_DEFAULT_2_2_2: c_int = 3061;
pub const XML_SCHEMAP_CVC_SIMPLE_TYPE: c_int = 3062;
pub const XML_SCHEMAP_COS_CT_EXTENDS_1_1: c_int = 3063;
pub const XML_SCHEMAP_SRC_IMPORT_1_1: c_int = 3064;
pub const XML_SCHEMAP_SRC_IMPORT_1_2: c_int = 3065;
pub const XML_SCHEMAP_SRC_IMPORT_2: c_int = 3066;
pub const XML_SCHEMAP_SRC_IMPORT_2_1: c_int = 3067;
pub const XML_SCHEMAP_SRC_IMPORT_2_2: c_int = 3068;
pub const XML_SCHEMAP_INTERNAL: c_int = 3069;
pub const XML_SCHEMAP_NOT_DETERMINISTIC: c_int = 3070;
pub const XML_SCHEMAP_SRC_ATTRIBUTE_GROUP_1: c_int = 3071;
pub const XML_SCHEMAP_SRC_ATTRIBUTE_GROUP_2: c_int = 3072;
pub const XML_SCHEMAP_SRC_ATTRIBUTE_GROUP_3: c_int = 3073;
pub const XML_SCHEMAP_MG_PROPS_CORRECT_1: c_int = 3074;
pub const XML_SCHEMAP_MG_PROPS_CORRECT_2: c_int = 3075;
pub const XML_SCHEMAP_SRC_CT_1: c_int = 3076;
pub const XML_SCHEMAP_DERIVATION_OK_RESTRICTION_2_1_3: c_int = 3077;
pub const XML_SCHEMAP_AU_PROPS_CORRECT_2: c_int = 3078;
pub const XML_SCHEMAP_A_PROPS_CORRECT_2: c_int = 3079;
pub const XML_SCHEMAP_C_PROPS_CORRECT: c_int = 3080;
pub const XML_SCHEMAP_SRC_REDEFINE: c_int = 3081;
pub const XML_SCHEMAP_SRC_IMPORT: c_int = 3082;
pub const XML_SCHEMAP_WARN_SKIP_SCHEMA: c_int = 3083;
pub const XML_SCHEMAP_WARN_UNLOCATED_SCHEMA: c_int = 3084;
pub const XML_SCHEMAP_WARN_ATTR_REDECL_PROH: c_int = 3085;
pub const XML_SCHEMAP_WARN_ATTR_POINTLESS_PROH: c_int = 3086;
pub const XML_SCHEMAP_AG_PROPS_CORRECT: c_int = 3087;
pub const XML_SCHEMAP_COS_CT_EXTENDS_1_2: c_int = 3088;
pub const XML_SCHEMAP_AU_PROPS_CORRECT: c_int = 3089;
pub const XML_SCHEMAP_A_PROPS_CORRECT_3: c_int = 3090;
pub const XML_SCHEMAP_COS_ALL_LIMITED: c_int = 3091;
pub const XML_SCHEMATRONV_ASSERT: c_int = 4000;
pub const XML_SCHEMATRONV_REPORT: c_int = 4001;
pub const XML_MODULE_OPEN: c_int = 4900;
pub const XML_MODULE_CLOSE: c_int = 4901;
pub const XML_CHECK_FOUND_ELEMENT: c_int = 5000;
pub const XML_CHECK_FOUND_ATTRIBUTE: c_int = 5001;
pub const XML_CHECK_FOUND_TEXT: c_int = 5002;
pub const XML_CHECK_FOUND_CDATA: c_int = 5003;
pub const XML_CHECK_FOUND_ENTITYREF: c_int = 5004;
pub const XML_CHECK_FOUND_ENTITY: c_int = 5005;
pub const XML_CHECK_FOUND_PI: c_int = 5006;
pub const XML_CHECK_FOUND_COMMENT: c_int = 5007;
pub const XML_CHECK_FOUND_DOCTYPE: c_int = 5008;
pub const XML_CHECK_FOUND_FRAGMENT: c_int = 5009;
pub const XML_CHECK_FOUND_NOTATION: c_int = 5010;
pub const XML_CHECK_UNKNOWN_NODE: c_int = 5011;
pub const XML_CHECK_ENTITY_TYPE: c_int = 5012;
pub const XML_CHECK_NO_PARENT: c_int = 5013;
pub const XML_CHECK_NO_DOC: c_int = 5014;
pub const XML_CHECK_NO_NAME: c_int = 5015;
pub const XML_CHECK_NO_ELEM: c_int = 5016;
pub const XML_CHECK_WRONG_DOC: c_int = 5017;
pub const XML_CHECK_NO_PREV: c_int = 5018;
pub const XML_CHECK_WRONG_PREV: c_int = 5019;
pub const XML_CHECK_NO_NEXT: c_int = 5020;
pub const XML_CHECK_WRONG_NEXT: c_int = 5021;
pub const XML_CHECK_NOT_DTD: c_int = 5022;
pub const XML_CHECK_NOT_ATTR: c_int = 5023;
pub const XML_CHECK_NOT_ATTR_DECL: c_int = 5024;
pub const XML_CHECK_NOT_ELEM_DECL: c_int = 5025;
pub const XML_CHECK_NOT_ENTITY_DECL: c_int = 5026;
pub const XML_CHECK_NOT_NS_DECL: c_int = 5027;
pub const XML_CHECK_NO_HREF: c_int = 5028;
pub const XML_CHECK_WRONG_PARENT: c_int = 5029;
pub const XML_CHECK_NS_SCOPE: c_int = 5030;
pub const XML_CHECK_NS_ANCESTOR: c_int = 5031;
pub const XML_CHECK_NOT_UTF8: c_int = 5032;
pub const XML_CHECK_NO_DICT: c_int = 5033;
pub const XML_CHECK_NOT_NCNAME: c_int = 5034;
pub const XML_CHECK_OUTSIDE_DICT: c_int = 5035;
pub const XML_CHECK_WRONG_NAME: c_int = 5036;
pub const XML_CHECK_NAME_NOT_NULL: c_int = 5037;
pub const XML_I18N_NO_NAME: c_int = 6000;
pub const XML_I18N_NO_HANDLER: c_int = 6001;
pub const XML_I18N_EXCESS_HANDLER: c_int = 6002;
pub const XML_I18N_CONV_FAILED: c_int = 6003;
pub const XML_I18N_NO_OUTPUT: c_int = 6004;
pub const XML_BUF_OVERFLOW: c_int = 7000;
pub const xmlParserErrors = c_uint;
pub const xmlGenericErrorFunc = ?*const fn (?*anyopaque, [*c]const u8, ...) callconv(.c) void;
pub extern fn xmlSetGenericErrorFunc(ctx: ?*anyopaque, handler: xmlGenericErrorFunc) void;
pub extern fn initGenericErrorDefaultFunc(handler: [*c]xmlGenericErrorFunc) void;
pub extern fn xmlSetStructuredErrorFunc(ctx: ?*anyopaque, handler: xmlStructuredErrorFunc) void;
pub extern fn xmlParserError(ctx: ?*anyopaque, msg: [*c]const u8, ...) void;
pub extern fn xmlParserWarning(ctx: ?*anyopaque, msg: [*c]const u8, ...) void;
pub extern fn xmlParserValidityError(ctx: ?*anyopaque, msg: [*c]const u8, ...) void;
pub extern fn xmlParserValidityWarning(ctx: ?*anyopaque, msg: [*c]const u8, ...) void;
pub extern fn xmlParserPrintFileInfo(input: xmlParserInputPtr) void;
pub extern fn xmlParserPrintFileContext(input: xmlParserInputPtr) void;
pub extern fn xmlGetLastError() xmlErrorPtr;
pub extern fn xmlResetLastError() void;
pub extern fn xmlCtxtGetLastError(ctx: ?*anyopaque) xmlErrorPtr;
pub extern fn xmlCtxtResetLastError(ctx: ?*anyopaque) void;
pub extern fn xmlResetError(err: xmlErrorPtr) void;
pub extern fn xmlCopyError(from: xmlErrorPtr, to: xmlErrorPtr) c_int;
pub const struct__xmlLink = opaque {};
pub const xmlLink = struct__xmlLink;
pub const xmlLinkPtr = ?*xmlLink;
pub const struct__xmlList = opaque {};
pub const xmlList = struct__xmlList;
pub const xmlListPtr = ?*xmlList;
pub const xmlListDeallocator = ?*const fn (xmlLinkPtr) callconv(.c) void;
pub const xmlListDataCompare = ?*const fn (?*const anyopaque, ?*const anyopaque) callconv(.c) c_int;
pub const xmlListWalker = ?*const fn (?*const anyopaque, ?*anyopaque) callconv(.c) c_int;
pub extern fn xmlListCreate(deallocator: xmlListDeallocator, compare: xmlListDataCompare) xmlListPtr;
pub extern fn xmlListDelete(l: xmlListPtr) void;
pub extern fn xmlListSearch(l: xmlListPtr, data: ?*anyopaque) ?*anyopaque;
pub extern fn xmlListReverseSearch(l: xmlListPtr, data: ?*anyopaque) ?*anyopaque;
pub extern fn xmlListInsert(l: xmlListPtr, data: ?*anyopaque) c_int;
pub extern fn xmlListAppend(l: xmlListPtr, data: ?*anyopaque) c_int;
pub extern fn xmlListRemoveFirst(l: xmlListPtr, data: ?*anyopaque) c_int;
pub extern fn xmlListRemoveLast(l: xmlListPtr, data: ?*anyopaque) c_int;
pub extern fn xmlListRemoveAll(l: xmlListPtr, data: ?*anyopaque) c_int;
pub extern fn xmlListClear(l: xmlListPtr) void;
pub extern fn xmlListEmpty(l: xmlListPtr) c_int;
pub extern fn xmlListFront(l: xmlListPtr) xmlLinkPtr;
pub extern fn xmlListEnd(l: xmlListPtr) xmlLinkPtr;
pub extern fn xmlListSize(l: xmlListPtr) c_int;
pub extern fn xmlListPopFront(l: xmlListPtr) void;
pub extern fn xmlListPopBack(l: xmlListPtr) void;
pub extern fn xmlListPushFront(l: xmlListPtr, data: ?*anyopaque) c_int;
pub extern fn xmlListPushBack(l: xmlListPtr, data: ?*anyopaque) c_int;
pub extern fn xmlListReverse(l: xmlListPtr) void;
pub extern fn xmlListSort(l: xmlListPtr) void;
pub extern fn xmlListWalk(l: xmlListPtr, walker: xmlListWalker, user: ?*anyopaque) void;
pub extern fn xmlListReverseWalk(l: xmlListPtr, walker: xmlListWalker, user: ?*anyopaque) void;
pub extern fn xmlListMerge(l1: xmlListPtr, l2: xmlListPtr) void;
pub extern fn xmlListDup(old: xmlListPtr) xmlListPtr;
pub extern fn xmlListCopy(cur: xmlListPtr, old: xmlListPtr) c_int;
pub extern fn xmlLinkGetData(lk: xmlLinkPtr) ?*anyopaque;
pub const xmlValidStatePtr = ?*xmlValidState;
pub const xmlValidCtxtPtr = [*c]xmlValidCtxt;
pub const xmlNotationTable = struct__xmlHashTable;
pub const xmlNotationTablePtr = ?*xmlNotationTable;
pub const xmlElementTable = struct__xmlHashTable;
pub const xmlElementTablePtr = ?*xmlElementTable;
pub const xmlAttributeTable = struct__xmlHashTable;
pub const xmlAttributeTablePtr = ?*xmlAttributeTable;
pub const xmlIDTable = struct__xmlHashTable;
pub const xmlIDTablePtr = ?*xmlIDTable;
pub const xmlRefTable = struct__xmlHashTable;
pub const xmlRefTablePtr = ?*xmlRefTable;
pub extern fn xmlAddNotationDecl(ctxt: xmlValidCtxtPtr, dtd: xmlDtdPtr, name: [*c]const xmlChar, PublicID: [*c]const xmlChar, SystemID: [*c]const xmlChar) xmlNotationPtr;
pub extern fn xmlCopyNotationTable(table: xmlNotationTablePtr) xmlNotationTablePtr;
pub extern fn xmlFreeNotationTable(table: xmlNotationTablePtr) void;
pub extern fn xmlNewElementContent(name: [*c]const xmlChar, @"type": xmlElementContentType) xmlElementContentPtr;
pub extern fn xmlCopyElementContent(content: xmlElementContentPtr) xmlElementContentPtr;
pub extern fn xmlFreeElementContent(cur: xmlElementContentPtr) void;
pub extern fn xmlNewDocElementContent(doc: xmlDocPtr, name: [*c]const xmlChar, @"type": xmlElementContentType) xmlElementContentPtr;
pub extern fn xmlCopyDocElementContent(doc: xmlDocPtr, content: xmlElementContentPtr) xmlElementContentPtr;
pub extern fn xmlFreeDocElementContent(doc: xmlDocPtr, cur: xmlElementContentPtr) void;
pub extern fn xmlSnprintfElementContent(buf: [*c]u8, size: c_int, content: xmlElementContentPtr, englob: c_int) void;
pub extern fn xmlAddElementDecl(ctxt: xmlValidCtxtPtr, dtd: xmlDtdPtr, name: [*c]const xmlChar, @"type": xmlElementTypeVal, content: xmlElementContentPtr) xmlElementPtr;
pub extern fn xmlCopyElementTable(table: xmlElementTablePtr) xmlElementTablePtr;
pub extern fn xmlFreeElementTable(table: xmlElementTablePtr) void;
pub extern fn xmlCreateEnumeration(name: [*c]const xmlChar) xmlEnumerationPtr;
pub extern fn xmlFreeEnumeration(cur: xmlEnumerationPtr) void;
pub extern fn xmlCopyEnumeration(cur: xmlEnumerationPtr) xmlEnumerationPtr;
pub extern fn xmlAddAttributeDecl(ctxt: xmlValidCtxtPtr, dtd: xmlDtdPtr, elem: [*c]const xmlChar, name: [*c]const xmlChar, ns: [*c]const xmlChar, @"type": xmlAttributeType, def: xmlAttributeDefault, defaultValue: [*c]const xmlChar, tree: xmlEnumerationPtr) xmlAttributePtr;
pub extern fn xmlCopyAttributeTable(table: xmlAttributeTablePtr) xmlAttributeTablePtr;
pub extern fn xmlFreeAttributeTable(table: xmlAttributeTablePtr) void;
pub extern fn xmlAddID(ctxt: xmlValidCtxtPtr, doc: xmlDocPtr, value: [*c]const xmlChar, attr: xmlAttrPtr) xmlIDPtr;
pub extern fn xmlFreeIDTable(table: xmlIDTablePtr) void;
pub extern fn xmlGetID(doc: xmlDocPtr, ID: [*c]const xmlChar) xmlAttrPtr;
pub extern fn xmlIsID(doc: xmlDocPtr, elem: xmlNodePtr, attr: xmlAttrPtr) c_int;
pub extern fn xmlRemoveID(doc: xmlDocPtr, attr: xmlAttrPtr) c_int;
pub extern fn xmlAddRef(ctxt: xmlValidCtxtPtr, doc: xmlDocPtr, value: [*c]const xmlChar, attr: xmlAttrPtr) xmlRefPtr;
pub extern fn xmlFreeRefTable(table: xmlRefTablePtr) void;
pub extern fn xmlIsRef(doc: xmlDocPtr, elem: xmlNodePtr, attr: xmlAttrPtr) c_int;
pub extern fn xmlRemoveRef(doc: xmlDocPtr, attr: xmlAttrPtr) c_int;
pub extern fn xmlGetRefs(doc: xmlDocPtr, ID: [*c]const xmlChar) xmlListPtr;
pub extern fn xmlValidateNotationUse(ctxt: xmlValidCtxtPtr, doc: xmlDocPtr, notationName: [*c]const xmlChar) c_int;
pub extern fn xmlIsMixedElement(doc: xmlDocPtr, name: [*c]const xmlChar) c_int;
pub extern fn xmlGetDtdAttrDesc(dtd: xmlDtdPtr, elem: [*c]const xmlChar, name: [*c]const xmlChar) xmlAttributePtr;
pub extern fn xmlGetDtdQAttrDesc(dtd: xmlDtdPtr, elem: [*c]const xmlChar, name: [*c]const xmlChar, prefix: [*c]const xmlChar) xmlAttributePtr;
pub extern fn xmlGetDtdNotationDesc(dtd: xmlDtdPtr, name: [*c]const xmlChar) xmlNotationPtr;
pub extern fn xmlGetDtdQElementDesc(dtd: xmlDtdPtr, name: [*c]const xmlChar, prefix: [*c]const xmlChar) xmlElementPtr;
pub extern fn xmlGetDtdElementDesc(dtd: xmlDtdPtr, name: [*c]const xmlChar) xmlElementPtr;
pub const XML_INTERNAL_GENERAL_ENTITY: c_int = 1;
pub const XML_EXTERNAL_GENERAL_PARSED_ENTITY: c_int = 2;
pub const XML_EXTERNAL_GENERAL_UNPARSED_ENTITY: c_int = 3;
pub const XML_INTERNAL_PARAMETER_ENTITY: c_int = 4;
pub const XML_EXTERNAL_PARAMETER_ENTITY: c_int = 5;
pub const XML_INTERNAL_PREDEFINED_ENTITY: c_int = 6;
pub const xmlEntityType = c_uint;
pub const xmlEntitiesTable = struct__xmlHashTable;
pub const xmlEntitiesTablePtr = ?*xmlEntitiesTable;
pub extern fn xmlNewEntity(doc: xmlDocPtr, name: [*c]const xmlChar, @"type": c_int, ExternalID: [*c]const xmlChar, SystemID: [*c]const xmlChar, content: [*c]const xmlChar) xmlEntityPtr;
pub extern fn xmlAddDocEntity(doc: xmlDocPtr, name: [*c]const xmlChar, @"type": c_int, ExternalID: [*c]const xmlChar, SystemID: [*c]const xmlChar, content: [*c]const xmlChar) xmlEntityPtr;
pub extern fn xmlAddDtdEntity(doc: xmlDocPtr, name: [*c]const xmlChar, @"type": c_int, ExternalID: [*c]const xmlChar, SystemID: [*c]const xmlChar, content: [*c]const xmlChar) xmlEntityPtr;
pub extern fn xmlGetPredefinedEntity(name: [*c]const xmlChar) xmlEntityPtr;
pub extern fn xmlGetDocEntity(doc: [*c]const xmlDoc, name: [*c]const xmlChar) xmlEntityPtr;
pub extern fn xmlGetDtdEntity(doc: xmlDocPtr, name: [*c]const xmlChar) xmlEntityPtr;
pub extern fn xmlGetParameterEntity(doc: xmlDocPtr, name: [*c]const xmlChar) xmlEntityPtr;
pub extern fn xmlEncodeEntitiesReentrant(doc: xmlDocPtr, input: [*c]const xmlChar) [*c]xmlChar;
pub extern fn xmlEncodeSpecialChars(doc: [*c]const xmlDoc, input: [*c]const xmlChar) [*c]xmlChar;
pub extern fn xmlCreateEntitiesTable() xmlEntitiesTablePtr;
pub extern fn xmlCopyEntitiesTable(table: xmlEntitiesTablePtr) xmlEntitiesTablePtr;
pub extern fn xmlFreeEntitiesTable(table: xmlEntitiesTablePtr) void;
pub const xmlParserNodeInfoPtr = [*c]xmlParserNodeInfo;
pub const xmlParserNodeInfoSeqPtr = [*c]xmlParserNodeInfoSeq;
pub const XML_PARSER_EOF: c_int = -1;
pub const XML_PARSER_START: c_int = 0;
pub const XML_PARSER_MISC: c_int = 1;
pub const XML_PARSER_PI: c_int = 2;
pub const XML_PARSER_DTD: c_int = 3;
pub const XML_PARSER_PROLOG: c_int = 4;
pub const XML_PARSER_COMMENT: c_int = 5;
pub const XML_PARSER_START_TAG: c_int = 6;
pub const XML_PARSER_CONTENT: c_int = 7;
pub const XML_PARSER_CDATA_SECTION: c_int = 8;
pub const XML_PARSER_END_TAG: c_int = 9;
pub const XML_PARSER_ENTITY_DECL: c_int = 10;
pub const XML_PARSER_ENTITY_VALUE: c_int = 11;
pub const XML_PARSER_ATTRIBUTE_VALUE: c_int = 12;
pub const XML_PARSER_SYSTEM_LITERAL: c_int = 13;
pub const XML_PARSER_EPILOG: c_int = 14;
pub const XML_PARSER_IGNORE: c_int = 15;
pub const XML_PARSER_PUBLIC_LITERAL: c_int = 16;
pub const xmlParserInputState = c_int;
pub const XML_PARSE_UNKNOWN: c_int = 0;
pub const XML_PARSE_DOM: c_int = 1;
pub const XML_PARSE_SAX: c_int = 2;
pub const XML_PARSE_PUSH_DOM: c_int = 3;
pub const XML_PARSE_PUSH_SAX: c_int = 4;
pub const XML_PARSE_READER: c_int = 5;
pub const xmlParserMode = c_uint;
pub const attributeSAXFunc = ?*const fn (?*anyopaque, [*c]const xmlChar, [*c]const xmlChar) callconv(.c) void;
pub const struct__xmlSAXHandlerV1 = extern struct {
    internalSubset: internalSubsetSAXFunc = @import("std").mem.zeroes(internalSubsetSAXFunc),
    isStandalone: isStandaloneSAXFunc = @import("std").mem.zeroes(isStandaloneSAXFunc),
    hasInternalSubset: hasInternalSubsetSAXFunc = @import("std").mem.zeroes(hasInternalSubsetSAXFunc),
    hasExternalSubset: hasExternalSubsetSAXFunc = @import("std").mem.zeroes(hasExternalSubsetSAXFunc),
    resolveEntity: resolveEntitySAXFunc = @import("std").mem.zeroes(resolveEntitySAXFunc),
    getEntity: getEntitySAXFunc = @import("std").mem.zeroes(getEntitySAXFunc),
    entityDecl: entityDeclSAXFunc = @import("std").mem.zeroes(entityDeclSAXFunc),
    notationDecl: notationDeclSAXFunc = @import("std").mem.zeroes(notationDeclSAXFunc),
    attributeDecl: attributeDeclSAXFunc = @import("std").mem.zeroes(attributeDeclSAXFunc),
    elementDecl: elementDeclSAXFunc = @import("std").mem.zeroes(elementDeclSAXFunc),
    unparsedEntityDecl: unparsedEntityDeclSAXFunc = @import("std").mem.zeroes(unparsedEntityDeclSAXFunc),
    setDocumentLocator: setDocumentLocatorSAXFunc = @import("std").mem.zeroes(setDocumentLocatorSAXFunc),
    startDocument: startDocumentSAXFunc = @import("std").mem.zeroes(startDocumentSAXFunc),
    endDocument: endDocumentSAXFunc = @import("std").mem.zeroes(endDocumentSAXFunc),
    startElement: startElementSAXFunc = @import("std").mem.zeroes(startElementSAXFunc),
    endElement: endElementSAXFunc = @import("std").mem.zeroes(endElementSAXFunc),
    reference: referenceSAXFunc = @import("std").mem.zeroes(referenceSAXFunc),
    characters: charactersSAXFunc = @import("std").mem.zeroes(charactersSAXFunc),
    ignorableWhitespace: ignorableWhitespaceSAXFunc = @import("std").mem.zeroes(ignorableWhitespaceSAXFunc),
    processingInstruction: processingInstructionSAXFunc = @import("std").mem.zeroes(processingInstructionSAXFunc),
    comment: commentSAXFunc = @import("std").mem.zeroes(commentSAXFunc),
    warning: warningSAXFunc = @import("std").mem.zeroes(warningSAXFunc),
    @"error": errorSAXFunc = @import("std").mem.zeroes(errorSAXFunc),
    fatalError: fatalErrorSAXFunc = @import("std").mem.zeroes(fatalErrorSAXFunc),
    getParameterEntity: getParameterEntitySAXFunc = @import("std").mem.zeroes(getParameterEntitySAXFunc),
    cdataBlock: cdataBlockSAXFunc = @import("std").mem.zeroes(cdataBlockSAXFunc),
    externalSubset: externalSubsetSAXFunc = @import("std").mem.zeroes(externalSubsetSAXFunc),
    initialized: c_uint = @import("std").mem.zeroes(c_uint),
};
pub const xmlSAXHandlerV1 = struct__xmlSAXHandlerV1;
pub const xmlSAXHandlerV1Ptr = [*c]xmlSAXHandlerV1;
pub const xmlExternalEntityLoader = ?*const fn ([*c]const u8, [*c]const u8, xmlParserCtxtPtr) callconv(.c) xmlParserInputPtr;
pub const XML_ENC_ERR_SUCCESS: c_int = 0;
pub const XML_ENC_ERR_SPACE: c_int = -1;
pub const XML_ENC_ERR_INPUT: c_int = -2;
pub const XML_ENC_ERR_PARTIAL: c_int = -3;
pub const XML_ENC_ERR_INTERNAL: c_int = -4;
pub const XML_ENC_ERR_MEMORY: c_int = -5;
pub const xmlCharEncError = c_int;
pub const XML_CHAR_ENCODING_ERROR: c_int = -1;
pub const XML_CHAR_ENCODING_NONE: c_int = 0;
pub const XML_CHAR_ENCODING_UTF8: c_int = 1;
pub const XML_CHAR_ENCODING_UTF16LE: c_int = 2;
pub const XML_CHAR_ENCODING_UTF16BE: c_int = 3;
pub const XML_CHAR_ENCODING_UCS4LE: c_int = 4;
pub const XML_CHAR_ENCODING_UCS4BE: c_int = 5;
pub const XML_CHAR_ENCODING_EBCDIC: c_int = 6;
pub const XML_CHAR_ENCODING_UCS4_2143: c_int = 7;
pub const XML_CHAR_ENCODING_UCS4_3412: c_int = 8;
pub const XML_CHAR_ENCODING_UCS2: c_int = 9;
pub const XML_CHAR_ENCODING_8859_1: c_int = 10;
pub const XML_CHAR_ENCODING_8859_2: c_int = 11;
pub const XML_CHAR_ENCODING_8859_3: c_int = 12;
pub const XML_CHAR_ENCODING_8859_4: c_int = 13;
pub const XML_CHAR_ENCODING_8859_5: c_int = 14;
pub const XML_CHAR_ENCODING_8859_6: c_int = 15;
pub const XML_CHAR_ENCODING_8859_7: c_int = 16;
pub const XML_CHAR_ENCODING_8859_8: c_int = 17;
pub const XML_CHAR_ENCODING_8859_9: c_int = 18;
pub const XML_CHAR_ENCODING_2022_JP: c_int = 19;
pub const XML_CHAR_ENCODING_SHIFT_JIS: c_int = 20;
pub const XML_CHAR_ENCODING_EUC_JP: c_int = 21;
pub const XML_CHAR_ENCODING_ASCII: c_int = 22;
pub const xmlCharEncoding = c_int;
pub extern fn xmlInitCharEncodingHandlers() void;
pub extern fn xmlCleanupCharEncodingHandlers() void;
pub extern fn xmlRegisterCharEncodingHandler(handler: xmlCharEncodingHandlerPtr) void;
pub extern fn xmlGetCharEncodingHandler(enc: xmlCharEncoding) xmlCharEncodingHandlerPtr;
pub extern fn xmlFindCharEncodingHandler(name: [*c]const u8) xmlCharEncodingHandlerPtr;
pub extern fn xmlNewCharEncodingHandler(name: [*c]const u8, input: xmlCharEncodingInputFunc, output: xmlCharEncodingOutputFunc) xmlCharEncodingHandlerPtr;
pub extern fn xmlAddEncodingAlias(name: [*c]const u8, alias: [*c]const u8) c_int;
pub extern fn xmlDelEncodingAlias(alias: [*c]const u8) c_int;
pub extern fn xmlGetEncodingAlias(alias: [*c]const u8) [*c]const u8;
pub extern fn xmlCleanupEncodingAliases() void;
pub extern fn xmlParseCharEncoding(name: [*c]const u8) xmlCharEncoding;
pub extern fn xmlGetCharEncodingName(enc: xmlCharEncoding) [*c]const u8;
pub extern fn xmlDetectCharEncoding(in: [*c]const u8, len: c_int) xmlCharEncoding;
pub extern fn xmlCharEncOutFunc(handler: [*c]xmlCharEncodingHandler, out: xmlBufferPtr, in: xmlBufferPtr) c_int;
pub extern fn xmlCharEncInFunc(handler: [*c]xmlCharEncodingHandler, out: xmlBufferPtr, in: xmlBufferPtr) c_int;
pub extern fn xmlCharEncFirstLine(handler: [*c]xmlCharEncodingHandler, out: xmlBufferPtr, in: xmlBufferPtr) c_int;
pub extern fn xmlCharEncCloseFunc(handler: [*c]xmlCharEncodingHandler) c_int;
pub extern fn isolat1ToUTF8(out: [*c]u8, outlen: [*c]c_int, in: [*c]const u8, inlen: [*c]c_int) c_int;
pub const xmlInputMatchCallback = ?*const fn ([*c]const u8) callconv(.c) c_int;
pub const xmlInputOpenCallback = ?*const fn ([*c]const u8) callconv(.c) ?*anyopaque;
pub extern fn xmlCleanupInputCallbacks() void;
pub extern fn xmlPopInputCallbacks() c_int;
pub extern fn xmlRegisterDefaultInputCallbacks() void;
pub extern fn xmlAllocParserInputBuffer(enc: xmlCharEncoding) xmlParserInputBufferPtr;
pub extern fn xmlParserInputBufferCreateFilename(URI: [*c]const u8, enc: xmlCharEncoding) xmlParserInputBufferPtr;
pub extern fn xmlParserInputBufferCreateFile(file: [*c]FILE, enc: xmlCharEncoding) xmlParserInputBufferPtr;
pub extern fn xmlParserInputBufferCreateFd(fd: c_int, enc: xmlCharEncoding) xmlParserInputBufferPtr;
pub extern fn xmlParserInputBufferCreateMem(mem: [*c]const u8, size: c_int, enc: xmlCharEncoding) xmlParserInputBufferPtr;
pub extern fn xmlParserInputBufferCreateStatic(mem: [*c]const u8, size: c_int, enc: xmlCharEncoding) xmlParserInputBufferPtr;
pub extern fn xmlParserInputBufferCreateIO(ioread: xmlInputReadCallback, ioclose: xmlInputCloseCallback, ioctx: ?*anyopaque, enc: xmlCharEncoding) xmlParserInputBufferPtr;
pub extern fn xmlParserInputBufferRead(in: xmlParserInputBufferPtr, len: c_int) c_int;
pub extern fn xmlParserInputBufferGrow(in: xmlParserInputBufferPtr, len: c_int) c_int;
pub extern fn xmlParserInputBufferPush(in: xmlParserInputBufferPtr, len: c_int, buf: [*c]const u8) c_int;
pub extern fn xmlFreeParserInputBuffer(in: xmlParserInputBufferPtr) void;
pub extern fn xmlParserGetDirectory(filename: [*c]const u8) [*c]u8;
pub extern fn xmlRegisterInputCallbacks(matchFunc: xmlInputMatchCallback, openFunc: xmlInputOpenCallback, readFunc: xmlInputReadCallback, closeFunc: xmlInputCloseCallback) c_int;
pub extern fn __xmlParserInputBufferCreateFilename(URI: [*c]const u8, enc: xmlCharEncoding) xmlParserInputBufferPtr;
pub extern fn xmlCheckHTTPInput(ctxt: xmlParserCtxtPtr, ret: xmlParserInputPtr) xmlParserInputPtr;
pub extern fn xmlNoNetExternalEntityLoader(URL: [*c]const u8, ID: [*c]const u8, ctxt: xmlParserCtxtPtr) xmlParserInputPtr;
pub extern fn xmlNormalizeWindowsPath(path: [*c]const xmlChar) [*c]xmlChar;
pub extern fn xmlCheckFilename(path: [*c]const u8) c_int;
pub extern fn xmlFileMatch(filename: [*c]const u8) c_int;
pub extern fn xmlFileOpen(filename: [*c]const u8) ?*anyopaque;
pub extern fn xmlFileRead(context: ?*anyopaque, buffer: [*c]u8, len: c_int) c_int;
pub extern fn xmlFileClose(context: ?*anyopaque) c_int;
pub extern fn xmlInitParser() void;
pub extern fn xmlCleanupParser() void;
pub extern fn xmlParserInputRead(in: xmlParserInputPtr, len: c_int) c_int;
pub extern fn xmlParserInputGrow(in: xmlParserInputPtr, len: c_int) c_int;
pub extern fn xmlSubstituteEntitiesDefault(val: c_int) c_int;
pub extern fn xmlKeepBlanksDefault(val: c_int) c_int;
pub extern fn xmlStopParser(ctxt: xmlParserCtxtPtr) void;
pub extern fn xmlPedanticParserDefault(val: c_int) c_int;
pub extern fn xmlLineNumbersDefault(val: c_int) c_int;
pub extern fn xmlParseDocument(ctxt: xmlParserCtxtPtr) c_int;
pub extern fn xmlParseExtParsedEnt(ctxt: xmlParserCtxtPtr) c_int;
pub extern fn xmlParseInNodeContext(node: xmlNodePtr, data: [*c]const u8, datalen: c_int, options: c_int, lst: [*c]xmlNodePtr) xmlParserErrors;
pub extern fn xmlParseCtxtExternalEntity(ctx: xmlParserCtxtPtr, URL: [*c]const xmlChar, ID: [*c]const xmlChar, lst: [*c]xmlNodePtr) c_int;
pub extern fn xmlNewParserCtxt() xmlParserCtxtPtr;
pub extern fn xmlNewSAXParserCtxt(sax: [*c]const xmlSAXHandler, userData: ?*anyopaque) xmlParserCtxtPtr;
pub extern fn xmlInitParserCtxt(ctxt: xmlParserCtxtPtr) c_int;
pub extern fn xmlClearParserCtxt(ctxt: xmlParserCtxtPtr) void;
pub extern fn xmlFreeParserCtxt(ctxt: xmlParserCtxtPtr) void;
pub extern fn xmlCreateDocParserCtxt(cur: [*c]const xmlChar) xmlParserCtxtPtr;
pub extern fn xmlCreateIOParserCtxt(sax: xmlSAXHandlerPtr, user_data: ?*anyopaque, ioread: xmlInputReadCallback, ioclose: xmlInputCloseCallback, ioctx: ?*anyopaque, enc: xmlCharEncoding) xmlParserCtxtPtr;
pub extern fn xmlNewIOInputStream(ctxt: xmlParserCtxtPtr, input: xmlParserInputBufferPtr, enc: xmlCharEncoding) xmlParserInputPtr;
pub extern fn xmlParserFindNodeInfo(ctxt: xmlParserCtxtPtr, node: xmlNodePtr) [*c]const xmlParserNodeInfo;
pub extern fn xmlInitNodeInfoSeq(seq: xmlParserNodeInfoSeqPtr) void;
pub extern fn xmlClearNodeInfoSeq(seq: xmlParserNodeInfoSeqPtr) void;
pub extern fn xmlParserFindNodeInfoIndex(seq: xmlParserNodeInfoSeqPtr, node: xmlNodePtr) c_ulong;
pub extern fn xmlParserAddNodeInfo(ctxt: xmlParserCtxtPtr, info: xmlParserNodeInfoPtr) void;
pub extern fn xmlSetExternalEntityLoader(f: xmlExternalEntityLoader) void;
pub extern fn xmlGetExternalEntityLoader() xmlExternalEntityLoader;
pub extern fn xmlLoadExternalEntity(URL: [*c]const u8, ID: [*c]const u8, ctxt: xmlParserCtxtPtr) xmlParserInputPtr;
pub extern fn xmlByteConsumed(ctxt: xmlParserCtxtPtr) c_long;
pub const XML_PARSE_RECOVER: c_int = 1;
pub const XML_PARSE_NOENT: c_int = 2;
pub const XML_PARSE_DTDLOAD: c_int = 4;
pub const XML_PARSE_DTDATTR: c_int = 8;
pub const XML_PARSE_DTDVALID: c_int = 16;
pub const XML_PARSE_NOERROR: c_int = 32;
pub const XML_PARSE_NOWARNING: c_int = 64;
pub const XML_PARSE_PEDANTIC: c_int = 128;
pub const XML_PARSE_NOBLANKS: c_int = 256;
pub const XML_PARSE_SAX1: c_int = 512;
pub const XML_PARSE_XINCLUDE: c_int = 1024;
pub const XML_PARSE_NONET: c_int = 2048;
pub const XML_PARSE_NODICT: c_int = 4096;
pub const XML_PARSE_NSCLEAN: c_int = 8192;
pub const XML_PARSE_NOCDATA: c_int = 16384;
pub const XML_PARSE_NOXINCNODE: c_int = 32768;
pub const XML_PARSE_COMPACT: c_int = 65536;
pub const XML_PARSE_OLD10: c_int = 131072;
pub const XML_PARSE_NOBASEFIX: c_int = 262144;
pub const XML_PARSE_HUGE: c_int = 524288;
pub const XML_PARSE_OLDSAX: c_int = 1048576;
pub const XML_PARSE_IGNORE_ENC: c_int = 2097152;
pub const XML_PARSE_BIG_LINES: c_int = 4194304;
pub const xmlParserOption = c_uint;
pub extern fn xmlCtxtReset(ctxt: xmlParserCtxtPtr) void;
pub extern fn xmlCtxtResetPush(ctxt: xmlParserCtxtPtr, chunk: [*c]const u8, size: c_int, filename: [*c]const u8, encoding: [*c]const u8) c_int;
pub extern fn xmlCtxtUseOptions(ctxt: xmlParserCtxtPtr, options: c_int) c_int;
pub extern fn xmlReadDoc(cur: [*c]const xmlChar, URL: [*c]const u8, encoding: [*c]const u8, options: c_int) xmlDocPtr;
pub extern fn xmlReadFile(URL: [*c]const u8, encoding: [*c]const u8, options: c_int) xmlDocPtr;
pub extern fn xmlReadMemory(buffer: [*c]const u8, size: c_int, URL: [*c]const u8, encoding: [*c]const u8, options: c_int) xmlDocPtr;
pub extern fn xmlReadFd(fd: c_int, URL: [*c]const u8, encoding: [*c]const u8, options: c_int) xmlDocPtr;
pub extern fn xmlReadIO(ioread: xmlInputReadCallback, ioclose: xmlInputCloseCallback, ioctx: ?*anyopaque, URL: [*c]const u8, encoding: [*c]const u8, options: c_int) xmlDocPtr;
pub extern fn xmlCtxtReadDoc(ctxt: xmlParserCtxtPtr, cur: [*c]const xmlChar, URL: [*c]const u8, encoding: [*c]const u8, options: c_int) xmlDocPtr;
pub extern fn xmlCtxtReadFile(ctxt: xmlParserCtxtPtr, filename: [*c]const u8, encoding: [*c]const u8, options: c_int) xmlDocPtr;
pub extern fn xmlCtxtReadMemory(ctxt: xmlParserCtxtPtr, buffer: [*c]const u8, size: c_int, URL: [*c]const u8, encoding: [*c]const u8, options: c_int) xmlDocPtr;
pub extern fn xmlCtxtReadFd(ctxt: xmlParserCtxtPtr, fd: c_int, URL: [*c]const u8, encoding: [*c]const u8, options: c_int) xmlDocPtr;
pub extern fn xmlCtxtReadIO(ctxt: xmlParserCtxtPtr, ioread: xmlInputReadCallback, ioclose: xmlInputCloseCallback, ioctx: ?*anyopaque, URL: [*c]const u8, encoding: [*c]const u8, options: c_int) xmlDocPtr;
pub const XML_WITH_THREAD: c_int = 1;
pub const XML_WITH_TREE: c_int = 2;
pub const XML_WITH_OUTPUT: c_int = 3;
pub const XML_WITH_PUSH: c_int = 4;
pub const XML_WITH_READER: c_int = 5;
pub const XML_WITH_PATTERN: c_int = 6;
pub const XML_WITH_WRITER: c_int = 7;
pub const XML_WITH_SAX1: c_int = 8;
pub const XML_WITH_FTP: c_int = 9;
pub const XML_WITH_HTTP: c_int = 10;
pub const XML_WITH_VALID: c_int = 11;
pub const XML_WITH_HTML: c_int = 12;
pub const XML_WITH_LEGACY: c_int = 13;
pub const XML_WITH_C14N: c_int = 14;
pub const XML_WITH_CATALOG: c_int = 15;
pub const XML_WITH_XPATH: c_int = 16;
pub const XML_WITH_XPTR: c_int = 17;
pub const XML_WITH_XINCLUDE: c_int = 18;
pub const XML_WITH_ICONV: c_int = 19;
pub const XML_WITH_ISO8859X: c_int = 20;
pub const XML_WITH_UNICODE: c_int = 21;
pub const XML_WITH_REGEXP: c_int = 22;
pub const XML_WITH_AUTOMATA: c_int = 23;
pub const XML_WITH_EXPR: c_int = 24;
pub const XML_WITH_SCHEMAS: c_int = 25;
pub const XML_WITH_SCHEMATRON: c_int = 26;
pub const XML_WITH_MODULES: c_int = 27;
pub const XML_WITH_DEBUG: c_int = 28;
pub const XML_WITH_DEBUG_MEM: c_int = 29;
pub const XML_WITH_DEBUG_RUN: c_int = 30;
pub const XML_WITH_ZLIB: c_int = 31;
pub const XML_WITH_ICU: c_int = 32;
pub const XML_WITH_LZMA: c_int = 33;
pub const XML_WITH_NONE: c_int = 99999;
pub const xmlFeature = c_uint;
pub extern fn xmlHasFeature(feature: xmlFeature) c_int;
pub extern fn _wdupenv_s(_Buffer: [*c][*c]wchar_t, _BufferSizeInWords: [*c]usize, _VarName: [*c]const wchar_t) errno_t;
pub extern fn _itow_s(_Val: c_int, _DstBuf: [*c]wchar_t, _SizeInWords: usize, _Radix: c_int) errno_t;
pub extern fn _ltow_s(_Val: c_long, _DstBuf: [*c]wchar_t, _SizeInWords: usize, _Radix: c_int) errno_t;
pub extern fn _ultow_s(_Val: c_ulong, _DstBuf: [*c]wchar_t, _SizeInWords: usize, _Radix: c_int) errno_t;
pub extern fn _wgetenv_s(_ReturnSize: [*c]usize, _DstBuf: [*c]wchar_t, _DstSizeInWords: usize, _VarName: [*c]const wchar_t) errno_t;
pub extern fn _i64tow_s(_Val: c_longlong, _DstBuf: [*c]wchar_t, _SizeInWords: usize, _Radix: c_int) errno_t;
pub extern fn _ui64tow_s(_Val: c_ulonglong, _DstBuf: [*c]wchar_t, _SizeInWords: usize, _Radix: c_int) errno_t;
pub extern fn _wmakepath_s(_PathResult: [*c]wchar_t, _SizeInWords: usize, _Drive: [*c]const wchar_t, _Dir: [*c]const wchar_t, _Filename: [*c]const wchar_t, _Ext: [*c]const wchar_t) errno_t;
pub extern fn _wputenv_s(_Name: [*c]const wchar_t, _Value: [*c]const wchar_t) errno_t;
pub extern fn _wsearchenv_s(_Filename: [*c]const wchar_t, _EnvVar: [*c]const wchar_t, _ResultPath: [*c]wchar_t, _SizeInWords: usize) errno_t;
pub extern fn _wsplitpath_s(_FullPath: [*c]const wchar_t, _Drive: [*c]wchar_t, _DriveSizeInWords: usize, _Dir: [*c]wchar_t, _DirSizeInWords: usize, _Filename: [*c]wchar_t, _FilenameSizeInWords: usize, _Ext: [*c]wchar_t, _ExtSizeInWords: usize) errno_t;
pub const _onexit_t = ?*const fn () callconv(.c) c_int;
pub const struct__div_t = extern struct {
    quot: c_int = @import("std").mem.zeroes(c_int),
    rem: c_int = @import("std").mem.zeroes(c_int),
};
pub const div_t = struct__div_t;
pub const struct__ldiv_t = extern struct {
    quot: c_long = @import("std").mem.zeroes(c_long),
    rem: c_long = @import("std").mem.zeroes(c_long),
};
pub const ldiv_t = struct__ldiv_t;
pub const _LDOUBLE = extern struct {
    ld: [10]u8 = @import("std").mem.zeroes([10]u8),
};
pub const _CRT_DOUBLE = extern struct {
    x: f64 = @import("std").mem.zeroes(f64),
};
pub const _CRT_FLOAT = extern struct {
    f: f32 = @import("std").mem.zeroes(f32),
};
pub const _LONGDOUBLE = extern struct {
    x: c_longdouble = @import("std").mem.zeroes(c_longdouble),
};
pub const _LDBL12 = extern struct {
    ld12: [12]u8 = @import("std").mem.zeroes([12]u8),
};
pub extern fn ___mb_cur_max_func() c_int;
pub const _purecall_handler = ?*const fn () callconv(.c) void;
pub extern fn _set_purecall_handler(_Handler: _purecall_handler) _purecall_handler;
pub extern fn _get_purecall_handler() _purecall_handler;
pub const _invalid_parameter_handler = ?*const fn ([*c]const wchar_t, [*c]const wchar_t, [*c]const wchar_t, c_uint, usize) callconv(.c) void;
pub extern fn _set_invalid_parameter_handler(_Handler: _invalid_parameter_handler) _invalid_parameter_handler;
pub extern fn _get_invalid_parameter_handler() _invalid_parameter_handler;
pub extern fn _errno() [*c]c_int;
pub extern fn _set_errno(_Value: c_int) errno_t;
pub extern fn _get_errno(_Value: [*c]c_int) errno_t;
pub extern fn __doserrno() [*c]c_ulong;
pub extern fn _set_doserrno(_Value: c_ulong) errno_t;
pub extern fn _get_doserrno(_Value: [*c]c_ulong) errno_t;
pub extern fn __sys_errlist() [*c][*c]u8;
pub extern fn __sys_nerr() [*c]c_int;
pub extern fn __p___argv() [*c][*c][*c]u8;
pub extern fn __p__fmode() [*c]c_int;
pub extern fn __p___argc() [*c]c_int;
pub extern fn __p___wargv() [*c][*c][*c]wchar_t;
pub extern fn __p__pgmptr() [*c][*c]u8;
pub extern fn __p__wpgmptr() [*c][*c]wchar_t;
pub extern fn _get_pgmptr(_Value: [*c][*c]u8) errno_t;
pub extern fn _get_wpgmptr(_Value: [*c][*c]wchar_t) errno_t;
pub extern fn _set_fmode(_Mode: c_int) errno_t;
pub extern fn _get_fmode(_PMode: [*c]c_int) errno_t;
pub extern fn __p__environ() [*c][*c][*c]u8;
pub extern fn __p__wenviron() [*c][*c][*c]wchar_t;
pub extern fn __p__osplatform() [*c]c_uint;
pub extern fn __p__osver() [*c]c_uint;
pub extern fn __p__winver() [*c]c_uint;
pub extern fn __p__winmajor() [*c]c_uint;
pub extern fn __p__winminor() [*c]c_uint;
pub extern fn _get_osplatform(_Value: [*c]c_uint) errno_t;
pub extern fn _get_osver(_Value: [*c]c_uint) errno_t;
pub extern fn _get_winver(_Value: [*c]c_uint) errno_t;
pub extern fn _get_winmajor(_Value: [*c]c_uint) errno_t;
pub extern fn _get_winminor(_Value: [*c]c_uint) errno_t;
pub extern fn exit(_Code: c_int) noreturn;
pub extern fn _exit(_Code: c_int) noreturn;
pub extern fn quick_exit(_Code: c_int) noreturn;
pub fn _Exit(arg_status: c_int) callconv(.c) noreturn {
    var status = arg_status;
    _ = &status;
    _exit(status);
}
pub extern fn abort() noreturn;
pub extern fn _set_abort_behavior(_Flags: c_uint, _Mask: c_uint) c_uint;
pub extern fn abs(_X: c_int) c_int;
pub extern fn labs(_X: c_long) c_long;
pub inline fn _abs64(arg_x: c_longlong) c_longlong {
    var x = arg_x;
    _ = &x;
    return __builtin_llabs(x);
}
pub extern fn atexit(?*const fn () callconv(.c) void) c_int;
pub extern fn at_quick_exit(?*const fn () callconv(.c) void) c_int;
pub extern fn atof(_String: [*c]const u8) f64;
pub extern fn _atof_l(_String: [*c]const u8, _Locale: _locale_t) f64;
pub extern fn atoi(_Str: [*c]const u8) c_int;
pub extern fn _atoi_l(_Str: [*c]const u8, _Locale: _locale_t) c_int;
pub extern fn atol(_Str: [*c]const u8) c_long;
pub extern fn _atol_l(_Str: [*c]const u8, _Locale: _locale_t) c_long;
pub extern fn bsearch(_Key: ?*const anyopaque, _Base: ?*const anyopaque, _NumOfElements: usize, _SizeOfElements: usize, _PtFuncCompare: ?*const fn (?*const anyopaque, ?*const anyopaque) callconv(.c) c_int) ?*anyopaque;
pub extern fn qsort(_Base: ?*anyopaque, _NumOfElements: usize, _SizeOfElements: usize, _PtFuncCompare: ?*const fn (?*const anyopaque, ?*const anyopaque) callconv(.c) c_int) void;
pub extern fn _byteswap_ushort(_Short: c_ushort) c_ushort;
pub extern fn _byteswap_ulong(_Long: c_ulong) c_ulong;
pub extern fn _byteswap_uint64(_Int64: c_ulonglong) c_ulonglong;
pub extern fn div(_Numerator: c_int, _Denominator: c_int) div_t;
pub extern fn getenv(_VarName: [*c]const u8) [*c]u8;
pub extern fn _itoa(_Value: c_int, _Dest: [*c]u8, _Radix: c_int) [*c]u8;
pub extern fn _i64toa(_Val: c_longlong, _DstBuf: [*c]u8, _Radix: c_int) [*c]u8;
pub extern fn _ui64toa(_Val: c_ulonglong, _DstBuf: [*c]u8, _Radix: c_int) [*c]u8;
pub extern fn _atoi64(_String: [*c]const u8) c_longlong;
pub extern fn _atoi64_l(_String: [*c]const u8, _Locale: _locale_t) c_longlong;
pub extern fn _strtoi64(_String: [*c]const u8, _EndPtr: [*c][*c]u8, _Radix: c_int) c_longlong;
pub extern fn _strtoi64_l(_String: [*c]const u8, _EndPtr: [*c][*c]u8, _Radix: c_int, _Locale: _locale_t) c_longlong;
pub extern fn _strtoui64(_String: [*c]const u8, _EndPtr: [*c][*c]u8, _Radix: c_int) c_ulonglong;
pub extern fn _strtoui64_l(_String: [*c]const u8, _EndPtr: [*c][*c]u8, _Radix: c_int, _Locale: _locale_t) c_ulonglong;
pub extern fn ldiv(_Numerator: c_long, _Denominator: c_long) ldiv_t;
pub extern fn _ltoa(_Value: c_long, _Dest: [*c]u8, _Radix: c_int) [*c]u8;
pub extern fn mblen(_Ch: [*c]const u8, _MaxCount: usize) c_int;
pub extern fn _mblen_l(_Ch: [*c]const u8, _MaxCount: usize, _Locale: _locale_t) c_int;
pub extern fn _mbstrlen(_Str: [*c]const u8) usize;
pub extern fn _mbstrlen_l(_Str: [*c]const u8, _Locale: _locale_t) usize;
pub extern fn _mbstrnlen(_Str: [*c]const u8, _MaxCount: usize) usize;
pub extern fn _mbstrnlen_l(_Str: [*c]const u8, _MaxCount: usize, _Locale: _locale_t) usize;
pub extern fn mbtowc(noalias _DstCh: [*c]wchar_t, noalias _SrcCh: [*c]const u8, _SrcSizeInBytes: usize) c_int;
pub extern fn _mbtowc_l(noalias _DstCh: [*c]wchar_t, noalias _SrcCh: [*c]const u8, _SrcSizeInBytes: usize, _Locale: _locale_t) c_int;
pub extern fn mbstowcs(noalias _Dest: [*c]wchar_t, noalias _Source: [*c]const u8, _MaxCount: usize) usize;
pub extern fn _mbstowcs_l(noalias _Dest: [*c]wchar_t, noalias _Source: [*c]const u8, _MaxCount: usize, _Locale: _locale_t) usize;
pub extern fn mkstemp(template_name: [*c]u8) c_int;
pub extern fn rand() c_int;
pub extern fn _set_error_mode(_Mode: c_int) c_int;
pub extern fn srand(_Seed: c_uint) void;
pub extern fn strtod(_Str: [*c]const u8, _EndPtr: [*c][*c]u8) f64;
pub extern fn strtof(nptr: [*c]const u8, endptr: [*c][*c]u8) f32;
pub extern fn strtold([*c]const u8, [*c][*c]u8) c_longdouble;
pub extern fn __strtod(noalias [*c]const u8, noalias [*c][*c]u8) f64;
pub extern fn __mingw_strtof(noalias [*c]const u8, noalias [*c][*c]u8) f32;
pub extern fn __mingw_strtod(noalias [*c]const u8, noalias [*c][*c]u8) f64;
pub extern fn __mingw_strtold(noalias [*c]const u8, noalias [*c][*c]u8) c_longdouble;
pub extern fn _strtof_l(noalias _Str: [*c]const u8, noalias _EndPtr: [*c][*c]u8, _Locale: _locale_t) f32;
pub extern fn _strtod_l(noalias _Str: [*c]const u8, noalias _EndPtr: [*c][*c]u8, _Locale: _locale_t) f64;
pub extern fn strtol(_Str: [*c]const u8, _EndPtr: [*c][*c]u8, _Radix: c_int) c_long;
pub extern fn _strtol_l(noalias _Str: [*c]const u8, noalias _EndPtr: [*c][*c]u8, _Radix: c_int, _Locale: _locale_t) c_long;
pub extern fn strtoul(_Str: [*c]const u8, _EndPtr: [*c][*c]u8, _Radix: c_int) c_ulong;
pub extern fn _strtoul_l(noalias _Str: [*c]const u8, noalias _EndPtr: [*c][*c]u8, _Radix: c_int, _Locale: _locale_t) c_ulong;
pub extern fn system(_Command: [*c]const u8) c_int;
pub extern fn _ultoa(_Value: c_ulong, _Dest: [*c]u8, _Radix: c_int) [*c]u8;
pub extern fn wctomb(_MbCh: [*c]u8, _WCh: wchar_t) c_int;
pub extern fn _wctomb_l(_MbCh: [*c]u8, _WCh: wchar_t, _Locale: _locale_t) c_int;
pub extern fn wcstombs(noalias _Dest: [*c]u8, noalias _Source: [*c]const wchar_t, _MaxCount: usize) usize;
pub extern fn _wcstombs_l(noalias _Dest: [*c]u8, noalias _Source: [*c]const wchar_t, _MaxCount: usize, _Locale: _locale_t) usize;
pub extern fn calloc(_NumOfElements: c_ulonglong, _SizeOfElements: c_ulonglong) ?*anyopaque;
pub extern fn free(_Memory: ?*anyopaque) void;
pub extern fn malloc(_Size: c_ulonglong) ?*anyopaque;
pub extern fn realloc(_Memory: ?*anyopaque, _NewSize: c_ulonglong) ?*anyopaque;
pub extern fn _aligned_free(_Memory: ?*anyopaque) void;
pub extern fn _aligned_malloc(_Size: usize, _Alignment: usize) ?*anyopaque;
pub extern fn _aligned_offset_malloc(_Size: usize, _Alignment: usize, _Offset: usize) ?*anyopaque;
pub extern fn _aligned_realloc(_Memory: ?*anyopaque, _Size: usize, _Alignment: usize) ?*anyopaque;
pub extern fn _aligned_offset_realloc(_Memory: ?*anyopaque, _Size: usize, _Alignment: usize, _Offset: usize) ?*anyopaque;
pub extern fn _recalloc(_Memory: ?*anyopaque, _Count: usize, _Size: usize) ?*anyopaque;
pub extern fn _aligned_recalloc(_Memory: ?*anyopaque, _Count: usize, _Size: usize, _Alignment: usize) ?*anyopaque;
pub extern fn _aligned_offset_recalloc(_Memory: ?*anyopaque, _Count: usize, _Size: usize, _Alignment: usize, _Offset: usize) ?*anyopaque;
pub extern fn _aligned_msize(_Memory: ?*anyopaque, _Alignment: usize, _Offset: usize) usize;
pub extern fn _itow(_Value: c_int, _Dest: [*c]wchar_t, _Radix: c_int) [*c]wchar_t;
pub extern fn _ltow(_Value: c_long, _Dest: [*c]wchar_t, _Radix: c_int) [*c]wchar_t;
pub extern fn _ultow(_Value: c_ulong, _Dest: [*c]wchar_t, _Radix: c_int) [*c]wchar_t;
pub extern fn __mingw_wcstod(noalias _Str: [*c]const wchar_t, noalias _EndPtr: [*c][*c]wchar_t) f64;
pub extern fn __mingw_wcstof(noalias nptr: [*c]const wchar_t, noalias endptr: [*c][*c]wchar_t) f32;
pub extern fn __mingw_wcstold(noalias [*c]const wchar_t, noalias [*c][*c]wchar_t) c_longdouble;
pub extern fn wcstod(noalias _Str: [*c]const wchar_t, noalias _EndPtr: [*c][*c]wchar_t) f64;
pub extern fn wcstof(noalias nptr: [*c]const wchar_t, noalias endptr: [*c][*c]wchar_t) f32;
pub extern fn wcstold(noalias [*c]const wchar_t, noalias [*c][*c]wchar_t) c_longdouble;
pub extern fn _wcstod_l(noalias _Str: [*c]const wchar_t, noalias _EndPtr: [*c][*c]wchar_t, _Locale: _locale_t) f64;
pub extern fn _wcstof_l(noalias _Str: [*c]const wchar_t, noalias _EndPtr: [*c][*c]wchar_t, _Locale: _locale_t) f32;
pub extern fn wcstol(noalias _Str: [*c]const wchar_t, noalias _EndPtr: [*c][*c]wchar_t, _Radix: c_int) c_long;
pub extern fn _wcstol_l(noalias _Str: [*c]const wchar_t, noalias _EndPtr: [*c][*c]wchar_t, _Radix: c_int, _Locale: _locale_t) c_long;
pub extern fn wcstoul(noalias _Str: [*c]const wchar_t, noalias _EndPtr: [*c][*c]wchar_t, _Radix: c_int) c_ulong;
pub extern fn _wcstoul_l(noalias _Str: [*c]const wchar_t, noalias _EndPtr: [*c][*c]wchar_t, _Radix: c_int, _Locale: _locale_t) c_ulong;
pub extern fn _wgetenv(_VarName: [*c]const wchar_t) [*c]wchar_t;
pub extern fn _wsystem(_Command: [*c]const wchar_t) c_int;
pub extern fn _wtof(_Str: [*c]const wchar_t) f64;
pub extern fn _wtof_l(_Str: [*c]const wchar_t, _Locale: _locale_t) f64;
pub extern fn _wtoi(_Str: [*c]const wchar_t) c_int;
pub extern fn _wtoi_l(_Str: [*c]const wchar_t, _Locale: _locale_t) c_int;
pub extern fn _wtol(_Str: [*c]const wchar_t) c_long;
pub extern fn _wtol_l(_Str: [*c]const wchar_t, _Locale: _locale_t) c_long;
pub extern fn _i64tow(_Val: c_longlong, _DstBuf: [*c]wchar_t, _Radix: c_int) [*c]wchar_t;
pub extern fn _ui64tow(_Val: c_ulonglong, _DstBuf: [*c]wchar_t, _Radix: c_int) [*c]wchar_t;
pub extern fn _wtoi64(_Str: [*c]const wchar_t) c_longlong;
pub extern fn _wtoi64_l(_Str: [*c]const wchar_t, _Locale: _locale_t) c_longlong;
pub extern fn _wcstoi64(_Str: [*c]const wchar_t, _EndPtr: [*c][*c]wchar_t, _Radix: c_int) c_longlong;
pub extern fn _wcstoi64_l(_Str: [*c]const wchar_t, _EndPtr: [*c][*c]wchar_t, _Radix: c_int, _Locale: _locale_t) c_longlong;
pub extern fn _wcstoui64(_Str: [*c]const wchar_t, _EndPtr: [*c][*c]wchar_t, _Radix: c_int) c_ulonglong;
pub extern fn _wcstoui64_l(_Str: [*c]const wchar_t, _EndPtr: [*c][*c]wchar_t, _Radix: c_int, _Locale: _locale_t) c_ulonglong;
pub extern fn _putenv(_EnvString: [*c]const u8) c_int;
pub extern fn _wputenv(_EnvString: [*c]const wchar_t) c_int;
pub extern fn _fullpath(_FullPath: [*c]u8, _Path: [*c]const u8, _SizeInBytes: usize) [*c]u8;
pub extern fn _ecvt(_Val: f64, _NumOfDigits: c_int, _PtDec: [*c]c_int, _PtSign: [*c]c_int) [*c]u8;
pub extern fn _fcvt(_Val: f64, _NumOfDec: c_int, _PtDec: [*c]c_int, _PtSign: [*c]c_int) [*c]u8;
pub extern fn _gcvt(_Val: f64, _NumOfDigits: c_int, _DstBuf: [*c]u8) [*c]u8;
pub extern fn _atodbl(_Result: [*c]_CRT_DOUBLE, _Str: [*c]u8) c_int;
pub extern fn _atoldbl(_Result: [*c]_LDOUBLE, _Str: [*c]u8) c_int;
pub extern fn _atoflt(_Result: [*c]_CRT_FLOAT, _Str: [*c]u8) c_int;
pub extern fn _atodbl_l(_Result: [*c]_CRT_DOUBLE, _Str: [*c]u8, _Locale: _locale_t) c_int;
pub extern fn _atoldbl_l(_Result: [*c]_LDOUBLE, _Str: [*c]u8, _Locale: _locale_t) c_int;
pub extern fn _atoflt_l(_Result: [*c]_CRT_FLOAT, _Str: [*c]u8, _Locale: _locale_t) c_int;
pub extern fn _lrotl(c_ulong, c_int) c_ulong;
pub extern fn _lrotr(c_ulong, c_int) c_ulong;
pub extern fn _makepath(_Path: [*c]u8, _Drive: [*c]const u8, _Dir: [*c]const u8, _Filename: [*c]const u8, _Ext: [*c]const u8) void;
pub extern fn _onexit(_Func: _onexit_t) _onexit_t;
pub extern fn _rotl64(_Val: c_ulonglong, _Shift: c_int) c_ulonglong;
pub extern fn _rotr64(Value: c_ulonglong, Shift: c_int) c_ulonglong;
pub extern fn _rotr(_Val: c_uint, _Shift: c_int) c_uint;
pub extern fn _rotl(_Val: c_uint, _Shift: c_int) c_uint;
pub extern fn _searchenv(_Filename: [*c]const u8, _EnvVar: [*c]const u8, _ResultPath: [*c]u8) void;
pub extern fn _splitpath(_FullPath: [*c]const u8, _Drive: [*c]u8, _Dir: [*c]u8, _Filename: [*c]u8, _Ext: [*c]u8) void;
pub extern fn _swab(_Buf1: [*c]u8, _Buf2: [*c]u8, _SizeInBytes: c_int) void;
pub extern fn _wfullpath(_FullPath: [*c]wchar_t, _Path: [*c]const wchar_t, _SizeInWords: usize) [*c]wchar_t;
pub extern fn _wmakepath(_ResultPath: [*c]wchar_t, _Drive: [*c]const wchar_t, _Dir: [*c]const wchar_t, _Filename: [*c]const wchar_t, _Ext: [*c]const wchar_t) void;
pub extern fn _wsearchenv(_Filename: [*c]const wchar_t, _EnvVar: [*c]const wchar_t, _ResultPath: [*c]wchar_t) void;
pub extern fn _wsplitpath(_FullPath: [*c]const wchar_t, _Drive: [*c]wchar_t, _Dir: [*c]wchar_t, _Filename: [*c]wchar_t, _Ext: [*c]wchar_t) void;
pub extern fn _beep(_Frequency: c_uint, _Duration: c_uint) void;
pub extern fn _seterrormode(_Mode: c_int) void;
pub extern fn _sleep(_Duration: c_ulong) void;
pub extern fn ecvt(_Val: f64, _NumOfDigits: c_int, _PtDec: [*c]c_int, _PtSign: [*c]c_int) [*c]u8;
pub extern fn fcvt(_Val: f64, _NumOfDec: c_int, _PtDec: [*c]c_int, _PtSign: [*c]c_int) [*c]u8;
pub extern fn gcvt(_Val: f64, _NumOfDigits: c_int, _DstBuf: [*c]u8) [*c]u8;
pub extern fn itoa(_Val: c_int, _DstBuf: [*c]u8, _Radix: c_int) [*c]u8;
pub extern fn ltoa(_Val: c_long, _DstBuf: [*c]u8, _Radix: c_int) [*c]u8;
pub extern fn putenv(_EnvString: [*c]const u8) c_int;
pub extern fn swab(_Buf1: [*c]u8, _Buf2: [*c]u8, _SizeInBytes: c_int) void;
pub extern fn ultoa(_Val: c_ulong, _Dstbuf: [*c]u8, _Radix: c_int) [*c]u8;
pub extern fn onexit(_Func: _onexit_t) _onexit_t;
pub const lldiv_t = extern struct {
    quot: c_longlong = @import("std").mem.zeroes(c_longlong),
    rem: c_longlong = @import("std").mem.zeroes(c_longlong),
};
pub extern fn lldiv(c_longlong, c_longlong) lldiv_t;
pub fn llabs(arg__j: c_longlong) callconv(.c) c_longlong {
    var _j = arg__j;
    _ = &_j;
    return if (_j >= @as(c_longlong, @bitCast(@as(c_longlong, @as(c_int, 0))))) _j else -_j;
}
pub extern fn strtoll([*c]const u8, [*c][*c]u8, c_int) c_longlong;
pub extern fn strtoull([*c]const u8, [*c][*c]u8, c_int) c_ulonglong;
pub extern fn atoll([*c]const u8) c_longlong;
pub fn wtoll(arg__w: [*c]const wchar_t) callconv(.c) c_longlong {
    var _w = arg__w;
    _ = &_w;
    return _wtoi64(_w);
}
pub fn lltoa(arg__n: c_longlong, arg__c: [*c]u8, arg__i: c_int) callconv(.c) [*c]u8 {
    var _n = arg__n;
    _ = &_n;
    var _c = arg__c;
    _ = &_c;
    var _i = arg__i;
    _ = &_i;
    return _i64toa(_n, _c, _i);
}
pub fn ulltoa(arg__n: c_ulonglong, arg__c: [*c]u8, arg__i: c_int) callconv(.c) [*c]u8 {
    var _n = arg__n;
    _ = &_n;
    var _c = arg__c;
    _ = &_c;
    var _i = arg__i;
    _ = &_i;
    return _ui64toa(_n, _c, _i);
}
pub fn lltow(arg__n: c_longlong, arg__w: [*c]wchar_t, arg__i: c_int) callconv(.c) [*c]wchar_t {
    var _n = arg__n;
    _ = &_n;
    var _w = arg__w;
    _ = &_w;
    var _i = arg__i;
    _ = &_i;
    return _i64tow(_n, _w, _i);
}
pub fn ulltow(arg__n: c_ulonglong, arg__w: [*c]wchar_t, arg__i: c_int) callconv(.c) [*c]wchar_t {
    var _n = arg__n;
    _ = &_n;
    var _w = arg__w;
    _ = &_w;
    var _i = arg__i;
    _ = &_i;
    return _ui64tow(_n, _w, _i);
}
pub extern fn _dupenv_s(_PBuffer: [*c][*c]u8, _PBufferSizeInBytes: [*c]usize, _VarName: [*c]const u8) errno_t;
pub extern fn bsearch_s(_Key: ?*const anyopaque, _Base: ?*const anyopaque, _NumOfElements: rsize_t, _SizeOfElements: rsize_t, _PtFuncCompare: ?*const fn (?*anyopaque, ?*const anyopaque, ?*const anyopaque) callconv(.c) c_int, _Context: ?*anyopaque) ?*anyopaque;
pub extern fn getenv_s(_ReturnSize: [*c]usize, _DstBuf: [*c]u8, _DstSize: rsize_t, _VarName: [*c]const u8) errno_t;
pub extern fn _itoa_s(_Value: c_int, _DstBuf: [*c]u8, _Size: usize, _Radix: c_int) errno_t;
pub extern fn _i64toa_s(_Val: c_longlong, _DstBuf: [*c]u8, _Size: usize, _Radix: c_int) errno_t;
pub extern fn _ui64toa_s(_Val: c_ulonglong, _DstBuf: [*c]u8, _Size: usize, _Radix: c_int) errno_t;
pub extern fn _ltoa_s(_Val: c_long, _DstBuf: [*c]u8, _Size: usize, _Radix: c_int) errno_t;
pub extern fn mbstowcs_s(_PtNumOfCharConverted: [*c]usize, _DstBuf: [*c]wchar_t, _SizeInWords: usize, _SrcBuf: [*c]const u8, _MaxCount: usize) errno_t;
pub extern fn _mbstowcs_s_l(_PtNumOfCharConverted: [*c]usize, _DstBuf: [*c]wchar_t, _SizeInWords: usize, _SrcBuf: [*c]const u8, _MaxCount: usize, _Locale: _locale_t) errno_t;
pub extern fn _ultoa_s(_Val: c_ulong, _DstBuf: [*c]u8, _Size: usize, _Radix: c_int) errno_t;
pub extern fn wctomb_s(_SizeConverted: [*c]c_int, _MbCh: [*c]u8, _SizeInBytes: rsize_t, _WCh: wchar_t) errno_t;
pub extern fn _wctomb_s_l(_SizeConverted: [*c]c_int, _MbCh: [*c]u8, _SizeInBytes: usize, _WCh: wchar_t, _Locale: _locale_t) errno_t;
pub extern fn wcstombs_s(_PtNumOfCharConverted: [*c]usize, _Dst: [*c]u8, _DstSizeInBytes: usize, _Src: [*c]const wchar_t, _MaxCountInBytes: usize) errno_t;
pub extern fn _wcstombs_s_l(_PtNumOfCharConverted: [*c]usize, _Dst: [*c]u8, _DstSizeInBytes: usize, _Src: [*c]const wchar_t, _MaxCountInBytes: usize, _Locale: _locale_t) errno_t;
pub extern fn _ecvt_s(_DstBuf: [*c]u8, _Size: usize, _Val: f64, _NumOfDights: c_int, _PtDec: [*c]c_int, _PtSign: [*c]c_int) errno_t;
pub extern fn _fcvt_s(_DstBuf: [*c]u8, _Size: usize, _Val: f64, _NumOfDec: c_int, _PtDec: [*c]c_int, _PtSign: [*c]c_int) errno_t;
pub extern fn _gcvt_s(_DstBuf: [*c]u8, _Size: usize, _Val: f64, _NumOfDigits: c_int) errno_t;
pub extern fn _makepath_s(_PathResult: [*c]u8, _Size: usize, _Drive: [*c]const u8, _Dir: [*c]const u8, _Filename: [*c]const u8, _Ext: [*c]const u8) errno_t;
pub extern fn _putenv_s(_Name: [*c]const u8, _Value: [*c]const u8) errno_t;
pub extern fn _searchenv_s(_Filename: [*c]const u8, _EnvVar: [*c]const u8, _ResultPath: [*c]u8, _SizeInBytes: usize) errno_t;
pub extern fn _splitpath_s(_FullPath: [*c]const u8, _Drive: [*c]u8, _DriveSize: usize, _Dir: [*c]u8, _DirSize: usize, _Filename: [*c]u8, _FilenameSize: usize, _Ext: [*c]u8, _ExtSize: usize) errno_t;
pub extern fn qsort_s(_Base: ?*anyopaque, _NumOfElements: usize, _SizeOfElements: usize, _PtFuncCompare: ?*const fn (?*anyopaque, ?*const anyopaque, ?*const anyopaque) callconv(.c) c_int, _Context: ?*anyopaque) void;
pub const struct__heapinfo = extern struct {
    _pentry: [*c]c_int = @import("std").mem.zeroes([*c]c_int),
    _size: usize = @import("std").mem.zeroes(usize),
    _useflag: c_int = @import("std").mem.zeroes(c_int),
};
pub const _HEAPINFO = struct__heapinfo;
pub extern fn __p__amblksiz() [*c]c_uint;
pub extern fn __mingw_aligned_malloc(_Size: usize, _Alignment: usize) ?*anyopaque;
pub extern fn __mingw_aligned_free(_Memory: ?*anyopaque) void;
pub extern fn __mingw_aligned_offset_realloc(_Memory: ?*anyopaque, _Size: usize, _Alignment: usize, _Offset: usize) ?*anyopaque;
pub extern fn __mingw_aligned_offset_malloc(usize, usize, usize) ?*anyopaque;
pub extern fn __mingw_aligned_realloc(_Memory: ?*anyopaque, _Size: usize, _Offset: usize) ?*anyopaque;
pub extern fn __mingw_aligned_msize(memblock: ?*anyopaque, alignment: usize, offset: usize) usize;
pub inline fn _mm_malloc(arg___size: usize, arg___align: usize) ?*anyopaque {
    var __size = arg___size;
    _ = &__size;
    var __align = arg___align;
    _ = &__align;
    if (__align == @as(usize, @bitCast(@as(c_longlong, @as(c_int, 1))))) {
        return malloc(__size);
    }
    if (!((__align & (__align -% @as(usize, @bitCast(@as(c_longlong, @as(c_int, 1)))))) != 0) and (__align < @sizeOf(?*anyopaque))) {
        __align = @sizeOf(?*anyopaque);
    }
    var __mallocedMemory: ?*anyopaque = undefined;
    _ = &__mallocedMemory;
    __mallocedMemory = __mingw_aligned_malloc(__size, __align);
    return __mallocedMemory;
}
pub inline fn _mm_free(arg___p: ?*anyopaque) void {
    var __p = arg___p;
    _ = &__p;
    __mingw_aligned_free(__p);
}
pub extern fn _resetstkoflw() c_int;
pub extern fn _set_malloc_crt_max_wait(_NewValue: c_ulong) c_ulong;
pub extern fn _expand(_Memory: ?*anyopaque, _NewSize: usize) ?*anyopaque;
pub extern fn _msize(_Memory: ?*anyopaque) usize;
pub extern fn _get_sbh_threshold() usize;
pub extern fn _set_sbh_threshold(_NewValue: usize) c_int;
pub extern fn _set_amblksiz(_Value: usize) errno_t;
pub extern fn _get_amblksiz(_Value: [*c]usize) errno_t;
pub extern fn _heapadd(_Memory: ?*anyopaque, _Size: usize) c_int;
pub extern fn _heapchk() c_int;
pub extern fn _heapmin() c_int;
pub extern fn _heapset(_Fill: c_uint) c_int;
pub extern fn _heapwalk(_EntryInfo: [*c]_HEAPINFO) c_int;
pub extern fn _heapused(_Used: [*c]usize, _Commit: [*c]usize) usize;
pub extern fn _get_heap_handle() isize;
pub fn _MarkAllocaS(arg__Ptr: ?*anyopaque, arg__Marker: c_uint) callconv(.c) ?*anyopaque {
    var _Ptr = arg__Ptr;
    _ = &_Ptr;
    var _Marker = arg__Marker;
    _ = &_Marker;
    if (_Ptr != null) {
        @as([*c]c_uint, @ptrCast(@alignCast(_Ptr))).* = _Marker;
        _Ptr = @as(?*anyopaque, @ptrCast(@as([*c]u8, @ptrCast(@alignCast(_Ptr))) + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 16)))))));
    }
    return _Ptr;
}
pub fn _freea(arg__Memory: ?*anyopaque) callconv(.c) void {
    var _Memory = arg__Memory;
    _ = &_Memory;
    var _Marker: c_uint = undefined;
    _ = &_Marker;
    if (_Memory != null) {
        _Memory = @as(?*anyopaque, @ptrCast(@as([*c]u8, @ptrCast(@alignCast(_Memory))) - @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 16)))))));
        _Marker = @as([*c]c_uint, @ptrCast(@alignCast(_Memory))).*;
        if (_Marker == @as(c_uint, @bitCast(@as(c_int, 56797)))) {
            free(_Memory);
        }
    }
}
pub extern fn xmlSAX2GetPublicId(ctx: ?*anyopaque) [*c]const xmlChar;
pub extern fn xmlSAX2GetSystemId(ctx: ?*anyopaque) [*c]const xmlChar;
pub extern fn xmlSAX2SetDocumentLocator(ctx: ?*anyopaque, loc: xmlSAXLocatorPtr) void;
pub extern fn xmlSAX2GetLineNumber(ctx: ?*anyopaque) c_int;
pub extern fn xmlSAX2GetColumnNumber(ctx: ?*anyopaque) c_int;
pub extern fn xmlSAX2IsStandalone(ctx: ?*anyopaque) c_int;
pub extern fn xmlSAX2HasInternalSubset(ctx: ?*anyopaque) c_int;
pub extern fn xmlSAX2HasExternalSubset(ctx: ?*anyopaque) c_int;
pub extern fn xmlSAX2InternalSubset(ctx: ?*anyopaque, name: [*c]const xmlChar, ExternalID: [*c]const xmlChar, SystemID: [*c]const xmlChar) void;
pub extern fn xmlSAX2ExternalSubset(ctx: ?*anyopaque, name: [*c]const xmlChar, ExternalID: [*c]const xmlChar, SystemID: [*c]const xmlChar) void;
pub extern fn xmlSAX2GetEntity(ctx: ?*anyopaque, name: [*c]const xmlChar) xmlEntityPtr;
pub extern fn xmlSAX2GetParameterEntity(ctx: ?*anyopaque, name: [*c]const xmlChar) xmlEntityPtr;
pub extern fn xmlSAX2ResolveEntity(ctx: ?*anyopaque, publicId: [*c]const xmlChar, systemId: [*c]const xmlChar) xmlParserInputPtr;
pub extern fn xmlSAX2EntityDecl(ctx: ?*anyopaque, name: [*c]const xmlChar, @"type": c_int, publicId: [*c]const xmlChar, systemId: [*c]const xmlChar, content: [*c]xmlChar) void;
pub extern fn xmlSAX2AttributeDecl(ctx: ?*anyopaque, elem: [*c]const xmlChar, fullname: [*c]const xmlChar, @"type": c_int, def: c_int, defaultValue: [*c]const xmlChar, tree: xmlEnumerationPtr) void;
pub extern fn xmlSAX2ElementDecl(ctx: ?*anyopaque, name: [*c]const xmlChar, @"type": c_int, content: xmlElementContentPtr) void;
pub extern fn xmlSAX2NotationDecl(ctx: ?*anyopaque, name: [*c]const xmlChar, publicId: [*c]const xmlChar, systemId: [*c]const xmlChar) void;
pub extern fn xmlSAX2UnparsedEntityDecl(ctx: ?*anyopaque, name: [*c]const xmlChar, publicId: [*c]const xmlChar, systemId: [*c]const xmlChar, notationName: [*c]const xmlChar) void;
pub extern fn xmlSAX2StartDocument(ctx: ?*anyopaque) void;
pub extern fn xmlSAX2EndDocument(ctx: ?*anyopaque) void;
pub extern fn xmlSAX2StartElementNs(ctx: ?*anyopaque, localname: [*c]const xmlChar, prefix: [*c]const xmlChar, URI: [*c]const xmlChar, nb_namespaces: c_int, namespaces: [*c][*c]const xmlChar, nb_attributes: c_int, nb_defaulted: c_int, attributes: [*c][*c]const xmlChar) void;
pub extern fn xmlSAX2EndElementNs(ctx: ?*anyopaque, localname: [*c]const xmlChar, prefix: [*c]const xmlChar, URI: [*c]const xmlChar) void;
pub extern fn xmlSAX2Reference(ctx: ?*anyopaque, name: [*c]const xmlChar) void;
pub extern fn xmlSAX2Characters(ctx: ?*anyopaque, ch: [*c]const xmlChar, len: c_int) void;
pub extern fn xmlSAX2IgnorableWhitespace(ctx: ?*anyopaque, ch: [*c]const xmlChar, len: c_int) void;
pub extern fn xmlSAX2ProcessingInstruction(ctx: ?*anyopaque, target: [*c]const xmlChar, data: [*c]const xmlChar) void;
pub extern fn xmlSAX2Comment(ctx: ?*anyopaque, value: [*c]const xmlChar) void;
pub extern fn xmlSAX2CDataBlock(ctx: ?*anyopaque, value: [*c]const xmlChar, len: c_int) void;
pub extern fn xmlSAXVersion(hdlr: [*c]xmlSAXHandler, version: c_int) c_int;
pub extern fn xmlSAX2InitDefaultSAXHandler(hdlr: [*c]xmlSAXHandler, warning: c_int) void;
pub extern fn xmlDefaultSAXHandlerInit() void;
pub extern fn xmlInitGlobals() void;
pub extern fn xmlCleanupGlobals() void;
pub const xmlParserInputBufferCreateFilenameFunc = ?*const fn ([*c]const u8, xmlCharEncoding) callconv(.c) xmlParserInputBufferPtr;
pub const xmlOutputBufferCreateFilenameFunc = ?*const fn ([*c]const u8, xmlCharEncodingHandlerPtr, c_int) callconv(.c) xmlOutputBufferPtr;
pub extern fn xmlParserInputBufferCreateFilenameDefault(func: xmlParserInputBufferCreateFilenameFunc) xmlParserInputBufferCreateFilenameFunc;
pub extern fn xmlOutputBufferCreateFilenameDefault(func: xmlOutputBufferCreateFilenameFunc) xmlOutputBufferCreateFilenameFunc;
pub const xmlRegisterNodeFunc = ?*const fn (xmlNodePtr) callconv(.c) void;
pub const xmlDeregisterNodeFunc = ?*const fn (xmlNodePtr) callconv(.c) void;
pub const struct__xmlGlobalState = extern struct {
    xmlParserVersion: [*c]const u8 = @import("std").mem.zeroes([*c]const u8),
    xmlDefaultSAXLocator: xmlSAXLocator = @import("std").mem.zeroes(xmlSAXLocator),
    xmlDefaultSAXHandler: xmlSAXHandlerV1 = @import("std").mem.zeroes(xmlSAXHandlerV1),
    docbDefaultSAXHandler: xmlSAXHandlerV1 = @import("std").mem.zeroes(xmlSAXHandlerV1),
    htmlDefaultSAXHandler: xmlSAXHandlerV1 = @import("std").mem.zeroes(xmlSAXHandlerV1),
    xmlFree: xmlFreeFunc = @import("std").mem.zeroes(xmlFreeFunc),
    xmlMalloc: xmlMallocFunc = @import("std").mem.zeroes(xmlMallocFunc),
    xmlMemStrdup: xmlStrdupFunc = @import("std").mem.zeroes(xmlStrdupFunc),
    xmlRealloc: xmlReallocFunc = @import("std").mem.zeroes(xmlReallocFunc),
    xmlGenericError: xmlGenericErrorFunc = @import("std").mem.zeroes(xmlGenericErrorFunc),
    xmlStructuredError: xmlStructuredErrorFunc = @import("std").mem.zeroes(xmlStructuredErrorFunc),
    xmlGenericErrorContext: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    oldXMLWDcompatibility: c_int = @import("std").mem.zeroes(c_int),
    xmlBufferAllocScheme: xmlBufferAllocationScheme = @import("std").mem.zeroes(xmlBufferAllocationScheme),
    xmlDefaultBufferSize: c_int = @import("std").mem.zeroes(c_int),
    xmlSubstituteEntitiesDefaultValue: c_int = @import("std").mem.zeroes(c_int),
    xmlDoValidityCheckingDefaultValue: c_int = @import("std").mem.zeroes(c_int),
    xmlGetWarningsDefaultValue: c_int = @import("std").mem.zeroes(c_int),
    xmlKeepBlanksDefaultValue: c_int = @import("std").mem.zeroes(c_int),
    xmlLineNumbersDefaultValue: c_int = @import("std").mem.zeroes(c_int),
    xmlLoadExtDtdDefaultValue: c_int = @import("std").mem.zeroes(c_int),
    xmlParserDebugEntities: c_int = @import("std").mem.zeroes(c_int),
    xmlPedanticParserDefaultValue: c_int = @import("std").mem.zeroes(c_int),
    xmlSaveNoEmptyTags: c_int = @import("std").mem.zeroes(c_int),
    xmlIndentTreeOutput: c_int = @import("std").mem.zeroes(c_int),
    xmlTreeIndentString: [*c]const u8 = @import("std").mem.zeroes([*c]const u8),
    xmlRegisterNodeDefaultValue: xmlRegisterNodeFunc = @import("std").mem.zeroes(xmlRegisterNodeFunc),
    xmlDeregisterNodeDefaultValue: xmlDeregisterNodeFunc = @import("std").mem.zeroes(xmlDeregisterNodeFunc),
    xmlMallocAtomic: xmlMallocFunc = @import("std").mem.zeroes(xmlMallocFunc),
    xmlLastError: xmlError = @import("std").mem.zeroes(xmlError),
    xmlParserInputBufferCreateFilenameValue: xmlParserInputBufferCreateFilenameFunc = @import("std").mem.zeroes(xmlParserInputBufferCreateFilenameFunc),
    xmlOutputBufferCreateFilenameValue: xmlOutputBufferCreateFilenameFunc = @import("std").mem.zeroes(xmlOutputBufferCreateFilenameFunc),
    xmlStructuredErrorContext: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
};
pub const xmlGlobalState = struct__xmlGlobalState;
pub const xmlGlobalStatePtr = [*c]xmlGlobalState;
pub extern fn xmlInitializeGlobalState(gs: xmlGlobalStatePtr) void;
pub extern fn xmlThrDefSetGenericErrorFunc(ctx: ?*anyopaque, handler: xmlGenericErrorFunc) void;
pub extern fn xmlThrDefSetStructuredErrorFunc(ctx: ?*anyopaque, handler: xmlStructuredErrorFunc) void;
pub extern fn xmlRegisterNodeDefault(func: xmlRegisterNodeFunc) xmlRegisterNodeFunc;
pub extern fn xmlThrDefRegisterNodeDefault(func: xmlRegisterNodeFunc) xmlRegisterNodeFunc;
pub extern fn xmlDeregisterNodeDefault(func: xmlDeregisterNodeFunc) xmlDeregisterNodeFunc;
pub extern fn xmlThrDefDeregisterNodeDefault(func: xmlDeregisterNodeFunc) xmlDeregisterNodeFunc;
pub extern fn xmlThrDefOutputBufferCreateFilenameDefault(func: xmlOutputBufferCreateFilenameFunc) xmlOutputBufferCreateFilenameFunc;
pub extern fn xmlThrDefParserInputBufferCreateFilenameDefault(func: xmlParserInputBufferCreateFilenameFunc) xmlParserInputBufferCreateFilenameFunc;
pub extern var xmlMalloc: xmlMallocFunc;
pub extern var xmlMallocAtomic: xmlMallocFunc;
pub extern var xmlRealloc: xmlReallocFunc;
pub extern var xmlFree: xmlFreeFunc;
pub extern var xmlMemStrdup: xmlStrdupFunc;
pub extern fn __xmlLastError() [*c]xmlError;
pub extern var xmlLastError: xmlError;
pub extern fn __oldXMLWDcompatibility() [*c]c_int;
pub extern var oldXMLWDcompatibility: c_int;
pub extern fn __xmlBufferAllocScheme() [*c]xmlBufferAllocationScheme;
pub extern var xmlBufferAllocScheme: xmlBufferAllocationScheme;
pub extern fn xmlThrDefBufferAllocScheme(v: xmlBufferAllocationScheme) xmlBufferAllocationScheme;
pub extern fn __xmlDefaultBufferSize() [*c]c_int;
pub extern var xmlDefaultBufferSize: c_int;
pub extern fn xmlThrDefDefaultBufferSize(v: c_int) c_int;
pub extern fn __xmlDefaultSAXHandler() [*c]xmlSAXHandlerV1;
pub extern var xmlDefaultSAXHandler: xmlSAXHandlerV1;
pub extern fn __xmlDefaultSAXLocator() [*c]xmlSAXLocator;
pub extern var xmlDefaultSAXLocator: xmlSAXLocator;
pub extern fn __xmlDoValidityCheckingDefaultValue() [*c]c_int;
pub extern var xmlDoValidityCheckingDefaultValue: c_int;
pub extern fn xmlThrDefDoValidityCheckingDefaultValue(v: c_int) c_int;
pub extern fn __xmlGenericError() [*c]xmlGenericErrorFunc;
pub extern var xmlGenericError: xmlGenericErrorFunc;
pub extern fn __xmlStructuredError() [*c]xmlStructuredErrorFunc;
pub extern var xmlStructuredError: xmlStructuredErrorFunc;
pub extern fn __xmlGenericErrorContext() [*c]?*anyopaque;
pub extern var xmlGenericErrorContext: ?*anyopaque;
pub extern fn __xmlStructuredErrorContext() [*c]?*anyopaque;
pub extern var xmlStructuredErrorContext: ?*anyopaque;
pub extern fn __xmlGetWarningsDefaultValue() [*c]c_int;
pub extern var xmlGetWarningsDefaultValue: c_int;
pub extern fn xmlThrDefGetWarningsDefaultValue(v: c_int) c_int;
pub extern fn __xmlIndentTreeOutput() [*c]c_int;
pub extern var xmlIndentTreeOutput: c_int;
pub extern fn xmlThrDefIndentTreeOutput(v: c_int) c_int;
pub extern fn __xmlTreeIndentString() [*c][*c]const u8;
pub extern var xmlTreeIndentString: [*c]const u8;
pub extern fn xmlThrDefTreeIndentString(v: [*c]const u8) [*c]const u8;
pub extern fn __xmlKeepBlanksDefaultValue() [*c]c_int;
pub extern var xmlKeepBlanksDefaultValue: c_int;
pub extern fn xmlThrDefKeepBlanksDefaultValue(v: c_int) c_int;
pub extern fn __xmlLineNumbersDefaultValue() [*c]c_int;
pub extern var xmlLineNumbersDefaultValue: c_int;
pub extern fn xmlThrDefLineNumbersDefaultValue(v: c_int) c_int;
pub extern fn __xmlLoadExtDtdDefaultValue() [*c]c_int;
pub extern var xmlLoadExtDtdDefaultValue: c_int;
pub extern fn xmlThrDefLoadExtDtdDefaultValue(v: c_int) c_int;
pub extern fn __xmlParserDebugEntities() [*c]c_int;
pub extern var xmlParserDebugEntities: c_int;
pub extern fn xmlThrDefParserDebugEntities(v: c_int) c_int;
pub extern fn __xmlParserVersion() [*c][*c]const u8;
pub extern var xmlParserVersion: [*c]const u8;
pub extern fn __xmlPedanticParserDefaultValue() [*c]c_int;
pub extern var xmlPedanticParserDefaultValue: c_int;
pub extern fn xmlThrDefPedanticParserDefaultValue(v: c_int) c_int;
pub extern fn __xmlSaveNoEmptyTags() [*c]c_int;
pub extern var xmlSaveNoEmptyTags: c_int;
pub extern fn xmlThrDefSaveNoEmptyTags(v: c_int) c_int;
pub extern fn __xmlSubstituteEntitiesDefaultValue() [*c]c_int;
pub extern var xmlSubstituteEntitiesDefaultValue: c_int;
pub extern fn xmlThrDefSubstituteEntitiesDefaultValue(v: c_int) c_int;
pub extern fn __xmlRegisterNodeDefaultValue() [*c]xmlRegisterNodeFunc;
pub extern var xmlRegisterNodeDefaultValue: xmlRegisterNodeFunc;
pub extern fn __xmlDeregisterNodeDefaultValue() [*c]xmlDeregisterNodeFunc;
pub extern var xmlDeregisterNodeDefaultValue: xmlDeregisterNodeFunc;
pub extern fn __xmlParserInputBufferCreateFilenameValue() [*c]xmlParserInputBufferCreateFilenameFunc;
pub extern var xmlParserInputBufferCreateFilenameValue: xmlParserInputBufferCreateFilenameFunc;
pub extern fn __xmlOutputBufferCreateFilenameValue() [*c]xmlOutputBufferCreateFilenameFunc;
pub extern var xmlOutputBufferCreateFilenameValue: xmlOutputBufferCreateFilenameFunc;
pub extern fn xmlNewMutex() xmlMutexPtr;
pub extern fn xmlMutexLock(tok: xmlMutexPtr) void;
pub extern fn xmlMutexUnlock(tok: xmlMutexPtr) void;
pub extern fn xmlFreeMutex(tok: xmlMutexPtr) void;
pub extern fn xmlNewRMutex() xmlRMutexPtr;
pub extern fn xmlRMutexLock(tok: xmlRMutexPtr) void;
pub extern fn xmlRMutexUnlock(tok: xmlRMutexPtr) void;
pub extern fn xmlFreeRMutex(tok: xmlRMutexPtr) void;
pub extern fn xmlInitThreads() void;
pub extern fn xmlLockLibrary() void;
pub extern fn xmlUnlockLibrary() void;
pub extern fn xmlGetThreadId() c_int;
pub extern fn xmlIsMainThread() c_int;
pub extern fn xmlCleanupThreads() void;
pub extern fn xmlGetGlobalState() xmlGlobalStatePtr;
pub const struct__xmlRelaxNG = opaque {};
pub const xmlRelaxNG = struct__xmlRelaxNG;
pub const xmlRelaxNGPtr = ?*xmlRelaxNG;
pub const xmlRelaxNGValidityErrorFunc = ?*const fn (?*anyopaque, [*c]const u8, ...) callconv(.c) void;
pub const xmlRelaxNGValidityWarningFunc = ?*const fn (?*anyopaque, [*c]const u8, ...) callconv(.c) void;
pub const struct__xmlRelaxNGParserCtxt = opaque {};
pub const xmlRelaxNGParserCtxt = struct__xmlRelaxNGParserCtxt;
pub const xmlRelaxNGParserCtxtPtr = ?*xmlRelaxNGParserCtxt;
pub const struct__xmlRelaxNGValidCtxt = opaque {};
pub const xmlRelaxNGValidCtxt = struct__xmlRelaxNGValidCtxt;
pub const xmlRelaxNGValidCtxtPtr = ?*xmlRelaxNGValidCtxt;
pub const XML_RELAXNG_OK: c_int = 0;
pub const XML_RELAXNG_ERR_MEMORY: c_int = 1;
pub const XML_RELAXNG_ERR_TYPE: c_int = 2;
pub const XML_RELAXNG_ERR_TYPEVAL: c_int = 3;
pub const XML_RELAXNG_ERR_DUPID: c_int = 4;
pub const XML_RELAXNG_ERR_TYPECMP: c_int = 5;
pub const XML_RELAXNG_ERR_NOSTATE: c_int = 6;
pub const XML_RELAXNG_ERR_NODEFINE: c_int = 7;
pub const XML_RELAXNG_ERR_LISTEXTRA: c_int = 8;
pub const XML_RELAXNG_ERR_LISTEMPTY: c_int = 9;
pub const XML_RELAXNG_ERR_INTERNODATA: c_int = 10;
pub const XML_RELAXNG_ERR_INTERSEQ: c_int = 11;
pub const XML_RELAXNG_ERR_INTEREXTRA: c_int = 12;
pub const XML_RELAXNG_ERR_ELEMNAME: c_int = 13;
pub const XML_RELAXNG_ERR_ATTRNAME: c_int = 14;
pub const XML_RELAXNG_ERR_ELEMNONS: c_int = 15;
pub const XML_RELAXNG_ERR_ATTRNONS: c_int = 16;
pub const XML_RELAXNG_ERR_ELEMWRONGNS: c_int = 17;
pub const XML_RELAXNG_ERR_ATTRWRONGNS: c_int = 18;
pub const XML_RELAXNG_ERR_ELEMEXTRANS: c_int = 19;
pub const XML_RELAXNG_ERR_ATTREXTRANS: c_int = 20;
pub const XML_RELAXNG_ERR_ELEMNOTEMPTY: c_int = 21;
pub const XML_RELAXNG_ERR_NOELEM: c_int = 22;
pub const XML_RELAXNG_ERR_NOTELEM: c_int = 23;
pub const XML_RELAXNG_ERR_ATTRVALID: c_int = 24;
pub const XML_RELAXNG_ERR_CONTENTVALID: c_int = 25;
pub const XML_RELAXNG_ERR_EXTRACONTENT: c_int = 26;
pub const XML_RELAXNG_ERR_INVALIDATTR: c_int = 27;
pub const XML_RELAXNG_ERR_DATAELEM: c_int = 28;
pub const XML_RELAXNG_ERR_VALELEM: c_int = 29;
pub const XML_RELAXNG_ERR_LISTELEM: c_int = 30;
pub const XML_RELAXNG_ERR_DATATYPE: c_int = 31;
pub const XML_RELAXNG_ERR_VALUE: c_int = 32;
pub const XML_RELAXNG_ERR_LIST: c_int = 33;
pub const XML_RELAXNG_ERR_NOGRAMMAR: c_int = 34;
pub const XML_RELAXNG_ERR_EXTRADATA: c_int = 35;
pub const XML_RELAXNG_ERR_LACKDATA: c_int = 36;
pub const XML_RELAXNG_ERR_INTERNAL: c_int = 37;
pub const XML_RELAXNG_ERR_ELEMWRONG: c_int = 38;
pub const XML_RELAXNG_ERR_TEXTWRONG: c_int = 39;
pub const xmlRelaxNGValidErr = c_uint;
pub const XML_RELAXNGP_NONE: c_int = 0;
pub const XML_RELAXNGP_FREE_DOC: c_int = 1;
pub const XML_RELAXNGP_CRNG: c_int = 2;
pub const xmlRelaxNGParserFlag = c_uint;
pub extern fn xmlRelaxNGInitTypes() c_int;
pub extern fn xmlRelaxNGCleanupTypes() void;
pub extern fn xmlRelaxNGNewParserCtxt(URL: [*c]const u8) xmlRelaxNGParserCtxtPtr;
pub extern fn xmlRelaxNGNewMemParserCtxt(buffer: [*c]const u8, size: c_int) xmlRelaxNGParserCtxtPtr;
pub extern fn xmlRelaxNGNewDocParserCtxt(doc: xmlDocPtr) xmlRelaxNGParserCtxtPtr;
pub extern fn xmlRelaxParserSetFlag(ctxt: xmlRelaxNGParserCtxtPtr, flag: c_int) c_int;
pub extern fn xmlRelaxNGFreeParserCtxt(ctxt: xmlRelaxNGParserCtxtPtr) void;
pub extern fn xmlRelaxNGSetParserErrors(ctxt: xmlRelaxNGParserCtxtPtr, err: xmlRelaxNGValidityErrorFunc, warn: xmlRelaxNGValidityWarningFunc, ctx: ?*anyopaque) void;
pub extern fn xmlRelaxNGGetParserErrors(ctxt: xmlRelaxNGParserCtxtPtr, err: [*c]xmlRelaxNGValidityErrorFunc, warn: [*c]xmlRelaxNGValidityWarningFunc, ctx: [*c]?*anyopaque) c_int;
pub extern fn xmlRelaxNGSetParserStructuredErrors(ctxt: xmlRelaxNGParserCtxtPtr, serror: xmlStructuredErrorFunc, ctx: ?*anyopaque) void;
pub extern fn xmlRelaxNGParse(ctxt: xmlRelaxNGParserCtxtPtr) xmlRelaxNGPtr;
pub extern fn xmlRelaxNGFree(schema: xmlRelaxNGPtr) void;
pub extern fn xmlRelaxNGSetValidErrors(ctxt: xmlRelaxNGValidCtxtPtr, err: xmlRelaxNGValidityErrorFunc, warn: xmlRelaxNGValidityWarningFunc, ctx: ?*anyopaque) void;
pub extern fn xmlRelaxNGGetValidErrors(ctxt: xmlRelaxNGValidCtxtPtr, err: [*c]xmlRelaxNGValidityErrorFunc, warn: [*c]xmlRelaxNGValidityWarningFunc, ctx: [*c]?*anyopaque) c_int;
pub extern fn xmlRelaxNGSetValidStructuredErrors(ctxt: xmlRelaxNGValidCtxtPtr, serror: xmlStructuredErrorFunc, ctx: ?*anyopaque) void;
pub extern fn xmlRelaxNGNewValidCtxt(schema: xmlRelaxNGPtr) xmlRelaxNGValidCtxtPtr;
pub extern fn xmlRelaxNGFreeValidCtxt(ctxt: xmlRelaxNGValidCtxtPtr) void;
pub extern fn xmlRelaxNGValidateDoc(ctxt: xmlRelaxNGValidCtxtPtr, doc: xmlDocPtr) c_int;
pub extern fn xmlRelaxNGValidatePushElement(ctxt: xmlRelaxNGValidCtxtPtr, doc: xmlDocPtr, elem: xmlNodePtr) c_int;
pub extern fn xmlRelaxNGValidatePushCData(ctxt: xmlRelaxNGValidCtxtPtr, data: [*c]const xmlChar, len: c_int) c_int;
pub extern fn xmlRelaxNGValidatePopElement(ctxt: xmlRelaxNGValidCtxtPtr, doc: xmlDocPtr, elem: xmlNodePtr) c_int;
pub extern fn xmlRelaxNGValidateFullElement(ctxt: xmlRelaxNGValidCtxtPtr, doc: xmlDocPtr, elem: xmlNodePtr) c_int;
pub const XML_SCHEMAS_ERR_OK: c_int = 0;
pub const XML_SCHEMAS_ERR_NOROOT: c_int = 1;
pub const XML_SCHEMAS_ERR_UNDECLAREDELEM: c_int = 2;
pub const XML_SCHEMAS_ERR_NOTTOPLEVEL: c_int = 3;
pub const XML_SCHEMAS_ERR_MISSING: c_int = 4;
pub const XML_SCHEMAS_ERR_WRONGELEM: c_int = 5;
pub const XML_SCHEMAS_ERR_NOTYPE: c_int = 6;
pub const XML_SCHEMAS_ERR_NOROLLBACK: c_int = 7;
pub const XML_SCHEMAS_ERR_ISABSTRACT: c_int = 8;
pub const XML_SCHEMAS_ERR_NOTEMPTY: c_int = 9;
pub const XML_SCHEMAS_ERR_ELEMCONT: c_int = 10;
pub const XML_SCHEMAS_ERR_HAVEDEFAULT: c_int = 11;
pub const XML_SCHEMAS_ERR_NOTNILLABLE: c_int = 12;
pub const XML_SCHEMAS_ERR_EXTRACONTENT: c_int = 13;
pub const XML_SCHEMAS_ERR_INVALIDATTR: c_int = 14;
pub const XML_SCHEMAS_ERR_INVALIDELEM: c_int = 15;
pub const XML_SCHEMAS_ERR_NOTDETERMINIST: c_int = 16;
pub const XML_SCHEMAS_ERR_CONSTRUCT: c_int = 17;
pub const XML_SCHEMAS_ERR_INTERNAL: c_int = 18;
pub const XML_SCHEMAS_ERR_NOTSIMPLE: c_int = 19;
pub const XML_SCHEMAS_ERR_ATTRUNKNOWN: c_int = 20;
pub const XML_SCHEMAS_ERR_ATTRINVALID: c_int = 21;
pub const XML_SCHEMAS_ERR_VALUE: c_int = 22;
pub const XML_SCHEMAS_ERR_FACET: c_int = 23;
pub const XML_SCHEMAS_ERR_: c_int = 24;
pub const XML_SCHEMAS_ERR_XXX: c_int = 25;
pub const xmlSchemaValidError = c_uint;
pub const XML_SCHEMA_VAL_VC_I_CREATE: c_int = 1;
pub const xmlSchemaValidOption = c_uint;
pub const struct__xmlSchema = opaque {};
pub const xmlSchema = struct__xmlSchema;
pub const xmlSchemaPtr = ?*xmlSchema;
pub const xmlSchemaValidityErrorFunc = ?*const fn (?*anyopaque, [*c]const u8, ...) callconv(.c) void;
pub const xmlSchemaValidityWarningFunc = ?*const fn (?*anyopaque, [*c]const u8, ...) callconv(.c) void;
pub const struct__xmlSchemaParserCtxt = opaque {};
pub const xmlSchemaParserCtxt = struct__xmlSchemaParserCtxt;
pub const xmlSchemaParserCtxtPtr = ?*xmlSchemaParserCtxt;
pub const struct__xmlSchemaValidCtxt = opaque {};
pub const xmlSchemaValidCtxt = struct__xmlSchemaValidCtxt;
pub const xmlSchemaValidCtxtPtr = ?*xmlSchemaValidCtxt;
pub const xmlSchemaValidityLocatorFunc = ?*const fn (?*anyopaque, [*c][*c]const u8, [*c]c_ulong) callconv(.c) c_int;
pub extern fn xmlSchemaNewParserCtxt(URL: [*c]const u8) xmlSchemaParserCtxtPtr;
pub extern fn xmlSchemaNewMemParserCtxt(buffer: [*c]const u8, size: c_int) xmlSchemaParserCtxtPtr;
pub extern fn xmlSchemaNewDocParserCtxt(doc: xmlDocPtr) xmlSchemaParserCtxtPtr;
pub extern fn xmlSchemaFreeParserCtxt(ctxt: xmlSchemaParserCtxtPtr) void;
pub extern fn xmlSchemaSetParserErrors(ctxt: xmlSchemaParserCtxtPtr, err: xmlSchemaValidityErrorFunc, warn: xmlSchemaValidityWarningFunc, ctx: ?*anyopaque) void;
pub extern fn xmlSchemaSetParserStructuredErrors(ctxt: xmlSchemaParserCtxtPtr, serror: xmlStructuredErrorFunc, ctx: ?*anyopaque) void;
pub extern fn xmlSchemaGetParserErrors(ctxt: xmlSchemaParserCtxtPtr, err: [*c]xmlSchemaValidityErrorFunc, warn: [*c]xmlSchemaValidityWarningFunc, ctx: [*c]?*anyopaque) c_int;
pub extern fn xmlSchemaIsValid(ctxt: xmlSchemaValidCtxtPtr) c_int;
pub extern fn xmlSchemaParse(ctxt: xmlSchemaParserCtxtPtr) xmlSchemaPtr;
pub extern fn xmlSchemaFree(schema: xmlSchemaPtr) void;
pub extern fn xmlSchemaSetValidErrors(ctxt: xmlSchemaValidCtxtPtr, err: xmlSchemaValidityErrorFunc, warn: xmlSchemaValidityWarningFunc, ctx: ?*anyopaque) void;
pub extern fn xmlSchemaSetValidStructuredErrors(ctxt: xmlSchemaValidCtxtPtr, serror: xmlStructuredErrorFunc, ctx: ?*anyopaque) void;
pub extern fn xmlSchemaGetValidErrors(ctxt: xmlSchemaValidCtxtPtr, err: [*c]xmlSchemaValidityErrorFunc, warn: [*c]xmlSchemaValidityWarningFunc, ctx: [*c]?*anyopaque) c_int;
pub extern fn xmlSchemaSetValidOptions(ctxt: xmlSchemaValidCtxtPtr, options: c_int) c_int;
pub extern fn xmlSchemaValidateSetFilename(vctxt: xmlSchemaValidCtxtPtr, filename: [*c]const u8) void;
pub extern fn xmlSchemaValidCtxtGetOptions(ctxt: xmlSchemaValidCtxtPtr) c_int;
pub extern fn xmlSchemaNewValidCtxt(schema: xmlSchemaPtr) xmlSchemaValidCtxtPtr;
pub extern fn xmlSchemaFreeValidCtxt(ctxt: xmlSchemaValidCtxtPtr) void;
pub extern fn xmlSchemaValidateDoc(ctxt: xmlSchemaValidCtxtPtr, instance: xmlDocPtr) c_int;
pub extern fn xmlSchemaValidateOneElement(ctxt: xmlSchemaValidCtxtPtr, elem: xmlNodePtr) c_int;
pub extern fn xmlSchemaValidateStream(ctxt: xmlSchemaValidCtxtPtr, input: xmlParserInputBufferPtr, enc: xmlCharEncoding, sax: xmlSAXHandlerPtr, user_data: ?*anyopaque) c_int;
pub extern fn xmlSchemaValidateFile(ctxt: xmlSchemaValidCtxtPtr, filename: [*c]const u8, options: c_int) c_int;
pub extern fn xmlSchemaValidCtxtGetParserCtxt(ctxt: xmlSchemaValidCtxtPtr) xmlParserCtxtPtr;
pub const struct__xmlSchemaSAXPlug = opaque {};
pub const xmlSchemaSAXPlugStruct = struct__xmlSchemaSAXPlug;
pub const xmlSchemaSAXPlugPtr = ?*xmlSchemaSAXPlugStruct;
pub extern fn xmlSchemaSAXPlug(ctxt: xmlSchemaValidCtxtPtr, sax: [*c]xmlSAXHandlerPtr, user_data: [*c]?*anyopaque) xmlSchemaSAXPlugPtr;
pub extern fn xmlSchemaSAXUnplug(plug: xmlSchemaSAXPlugPtr) c_int;
pub extern fn xmlSchemaValidateSetLocator(vctxt: xmlSchemaValidCtxtPtr, f: xmlSchemaValidityLocatorFunc, ctxt: ?*anyopaque) void;
pub const XML_PARSER_SEVERITY_VALIDITY_WARNING: c_int = 1;
pub const XML_PARSER_SEVERITY_VALIDITY_ERROR: c_int = 2;
pub const XML_PARSER_SEVERITY_WARNING: c_int = 3;
pub const XML_PARSER_SEVERITY_ERROR: c_int = 4;
pub const xmlParserSeverities = c_uint;
pub const XML_TEXTREADER_MODE_INITIAL: c_int = 0;
pub const XML_TEXTREADER_MODE_INTERACTIVE: c_int = 1;
pub const XML_TEXTREADER_MODE_ERROR: c_int = 2;
pub const XML_TEXTREADER_MODE_EOF: c_int = 3;
pub const XML_TEXTREADER_MODE_CLOSED: c_int = 4;
pub const XML_TEXTREADER_MODE_READING: c_int = 5;
pub const xmlTextReaderMode = c_uint;
pub const XML_PARSER_LOADDTD: c_int = 1;
pub const XML_PARSER_DEFAULTATTRS: c_int = 2;
pub const XML_PARSER_VALIDATE: c_int = 3;
pub const XML_PARSER_SUBST_ENTITIES: c_int = 4;
pub const xmlParserProperties = c_uint;
pub const XML_READER_TYPE_NONE: c_int = 0;
pub const XML_READER_TYPE_ELEMENT: c_int = 1;
pub const XML_READER_TYPE_ATTRIBUTE: c_int = 2;
pub const XML_READER_TYPE_TEXT: c_int = 3;
pub const XML_READER_TYPE_CDATA: c_int = 4;
pub const XML_READER_TYPE_ENTITY_REFERENCE: c_int = 5;
pub const XML_READER_TYPE_ENTITY: c_int = 6;
pub const XML_READER_TYPE_PROCESSING_INSTRUCTION: c_int = 7;
pub const XML_READER_TYPE_COMMENT: c_int = 8;
pub const XML_READER_TYPE_DOCUMENT: c_int = 9;
pub const XML_READER_TYPE_DOCUMENT_TYPE: c_int = 10;
pub const XML_READER_TYPE_DOCUMENT_FRAGMENT: c_int = 11;
pub const XML_READER_TYPE_NOTATION: c_int = 12;
pub const XML_READER_TYPE_WHITESPACE: c_int = 13;
pub const XML_READER_TYPE_SIGNIFICANT_WHITESPACE: c_int = 14;
pub const XML_READER_TYPE_END_ELEMENT: c_int = 15;
pub const XML_READER_TYPE_END_ENTITY: c_int = 16;
pub const XML_READER_TYPE_XML_DECLARATION: c_int = 17;
pub const xmlReaderTypes = c_uint;
pub const struct__xmlTextReader = opaque {};
pub const xmlTextReader = struct__xmlTextReader;
pub const xmlTextReaderPtr = ?*xmlTextReader;
pub extern fn xmlNewTextReader(input: xmlParserInputBufferPtr, URI: [*c]const u8) xmlTextReaderPtr;
pub extern fn xmlNewTextReaderFilename(URI: [*c]const u8) xmlTextReaderPtr;
pub extern fn xmlFreeTextReader(reader: xmlTextReaderPtr) void;
pub extern fn xmlTextReaderSetup(reader: xmlTextReaderPtr, input: xmlParserInputBufferPtr, URL: [*c]const u8, encoding: [*c]const u8, options: c_int) c_int;
pub extern fn xmlTextReaderRead(reader: xmlTextReaderPtr) c_int;
pub extern fn xmlTextReaderReadString(reader: xmlTextReaderPtr) [*c]xmlChar;
pub extern fn xmlTextReaderReadAttributeValue(reader: xmlTextReaderPtr) c_int;
pub extern fn xmlTextReaderAttributeCount(reader: xmlTextReaderPtr) c_int;
pub extern fn xmlTextReaderDepth(reader: xmlTextReaderPtr) c_int;
pub extern fn xmlTextReaderHasAttributes(reader: xmlTextReaderPtr) c_int;
pub extern fn xmlTextReaderHasValue(reader: xmlTextReaderPtr) c_int;
pub extern fn xmlTextReaderIsDefault(reader: xmlTextReaderPtr) c_int;
pub extern fn xmlTextReaderIsEmptyElement(reader: xmlTextReaderPtr) c_int;
pub extern fn xmlTextReaderNodeType(reader: xmlTextReaderPtr) c_int;
pub extern fn xmlTextReaderQuoteChar(reader: xmlTextReaderPtr) c_int;
pub extern fn xmlTextReaderReadState(reader: xmlTextReaderPtr) c_int;
pub extern fn xmlTextReaderIsNamespaceDecl(reader: xmlTextReaderPtr) c_int;
pub extern fn xmlTextReaderConstBaseUri(reader: xmlTextReaderPtr) [*c]const xmlChar;
pub extern fn xmlTextReaderConstLocalName(reader: xmlTextReaderPtr) [*c]const xmlChar;
pub extern fn xmlTextReaderConstName(reader: xmlTextReaderPtr) [*c]const xmlChar;
pub extern fn xmlTextReaderConstNamespaceUri(reader: xmlTextReaderPtr) [*c]const xmlChar;
pub extern fn xmlTextReaderConstPrefix(reader: xmlTextReaderPtr) [*c]const xmlChar;
pub extern fn xmlTextReaderConstXmlLang(reader: xmlTextReaderPtr) [*c]const xmlChar;
pub extern fn xmlTextReaderConstString(reader: xmlTextReaderPtr, str: [*c]const xmlChar) [*c]const xmlChar;
pub extern fn xmlTextReaderConstValue(reader: xmlTextReaderPtr) [*c]const xmlChar;
pub extern fn xmlTextReaderBaseUri(reader: xmlTextReaderPtr) [*c]xmlChar;
pub extern fn xmlTextReaderLocalName(reader: xmlTextReaderPtr) [*c]xmlChar;
pub extern fn xmlTextReaderName(reader: xmlTextReaderPtr) [*c]xmlChar;
pub extern fn xmlTextReaderNamespaceUri(reader: xmlTextReaderPtr) [*c]xmlChar;
pub extern fn xmlTextReaderPrefix(reader: xmlTextReaderPtr) [*c]xmlChar;
pub extern fn xmlTextReaderXmlLang(reader: xmlTextReaderPtr) [*c]xmlChar;
pub extern fn xmlTextReaderValue(reader: xmlTextReaderPtr) [*c]xmlChar;
pub extern fn xmlTextReaderClose(reader: xmlTextReaderPtr) c_int;
pub extern fn xmlTextReaderGetAttributeNo(reader: xmlTextReaderPtr, no: c_int) [*c]xmlChar;
pub extern fn xmlTextReaderGetAttribute(reader: xmlTextReaderPtr, name: [*c]const xmlChar) [*c]xmlChar;
pub extern fn xmlTextReaderGetAttributeNs(reader: xmlTextReaderPtr, localName: [*c]const xmlChar, namespaceURI: [*c]const xmlChar) [*c]xmlChar;
pub extern fn xmlTextReaderGetRemainder(reader: xmlTextReaderPtr) xmlParserInputBufferPtr;
pub extern fn xmlTextReaderLookupNamespace(reader: xmlTextReaderPtr, prefix: [*c]const xmlChar) [*c]xmlChar;
pub extern fn xmlTextReaderMoveToAttributeNo(reader: xmlTextReaderPtr, no: c_int) c_int;
pub extern fn xmlTextReaderMoveToAttribute(reader: xmlTextReaderPtr, name: [*c]const xmlChar) c_int;
pub extern fn xmlTextReaderMoveToAttributeNs(reader: xmlTextReaderPtr, localName: [*c]const xmlChar, namespaceURI: [*c]const xmlChar) c_int;
pub extern fn xmlTextReaderMoveToFirstAttribute(reader: xmlTextReaderPtr) c_int;
pub extern fn xmlTextReaderMoveToNextAttribute(reader: xmlTextReaderPtr) c_int;
pub extern fn xmlTextReaderMoveToElement(reader: xmlTextReaderPtr) c_int;
pub extern fn xmlTextReaderNormalization(reader: xmlTextReaderPtr) c_int;
pub extern fn xmlTextReaderConstEncoding(reader: xmlTextReaderPtr) [*c]const xmlChar;
pub extern fn xmlTextReaderSetParserProp(reader: xmlTextReaderPtr, prop: c_int, value: c_int) c_int;
pub extern fn xmlTextReaderGetParserProp(reader: xmlTextReaderPtr, prop: c_int) c_int;
pub extern fn xmlTextReaderCurrentNode(reader: xmlTextReaderPtr) xmlNodePtr;
pub extern fn xmlTextReaderGetParserLineNumber(reader: xmlTextReaderPtr) c_int;
pub extern fn xmlTextReaderGetParserColumnNumber(reader: xmlTextReaderPtr) c_int;
pub extern fn xmlTextReaderPreserve(reader: xmlTextReaderPtr) xmlNodePtr;
pub extern fn xmlTextReaderCurrentDoc(reader: xmlTextReaderPtr) xmlDocPtr;
pub extern fn xmlTextReaderExpand(reader: xmlTextReaderPtr) xmlNodePtr;
pub extern fn xmlTextReaderNext(reader: xmlTextReaderPtr) c_int;
pub extern fn xmlTextReaderNextSibling(reader: xmlTextReaderPtr) c_int;
pub extern fn xmlTextReaderIsValid(reader: xmlTextReaderPtr) c_int;
pub extern fn xmlTextReaderRelaxNGValidate(reader: xmlTextReaderPtr, rng: [*c]const u8) c_int;
pub extern fn xmlTextReaderRelaxNGValidateCtxt(reader: xmlTextReaderPtr, ctxt: xmlRelaxNGValidCtxtPtr, options: c_int) c_int;
pub extern fn xmlTextReaderRelaxNGSetSchema(reader: xmlTextReaderPtr, schema: xmlRelaxNGPtr) c_int;
pub extern fn xmlTextReaderSchemaValidate(reader: xmlTextReaderPtr, xsd: [*c]const u8) c_int;
pub extern fn xmlTextReaderSchemaValidateCtxt(reader: xmlTextReaderPtr, ctxt: xmlSchemaValidCtxtPtr, options: c_int) c_int;
pub extern fn xmlTextReaderSetSchema(reader: xmlTextReaderPtr, schema: xmlSchemaPtr) c_int;
pub extern fn xmlTextReaderConstXmlVersion(reader: xmlTextReaderPtr) [*c]const xmlChar;
pub extern fn xmlTextReaderStandalone(reader: xmlTextReaderPtr) c_int;
pub extern fn xmlTextReaderByteConsumed(reader: xmlTextReaderPtr) c_long;
pub extern fn xmlReaderWalker(doc: xmlDocPtr) xmlTextReaderPtr;
pub extern fn xmlReaderForDoc(cur: [*c]const xmlChar, URL: [*c]const u8, encoding: [*c]const u8, options: c_int) xmlTextReaderPtr;
pub extern fn xmlReaderForFile(filename: [*c]const u8, encoding: [*c]const u8, options: c_int) xmlTextReaderPtr;
pub extern fn xmlReaderForMemory(buffer: [*c]const u8, size: c_int, URL: [*c]const u8, encoding: [*c]const u8, options: c_int) xmlTextReaderPtr;
pub extern fn xmlReaderForFd(fd: c_int, URL: [*c]const u8, encoding: [*c]const u8, options: c_int) xmlTextReaderPtr;
pub extern fn xmlReaderForIO(ioread: xmlInputReadCallback, ioclose: xmlInputCloseCallback, ioctx: ?*anyopaque, URL: [*c]const u8, encoding: [*c]const u8, options: c_int) xmlTextReaderPtr;
pub extern fn xmlReaderNewWalker(reader: xmlTextReaderPtr, doc: xmlDocPtr) c_int;
pub extern fn xmlReaderNewDoc(reader: xmlTextReaderPtr, cur: [*c]const xmlChar, URL: [*c]const u8, encoding: [*c]const u8, options: c_int) c_int;
pub extern fn xmlReaderNewFile(reader: xmlTextReaderPtr, filename: [*c]const u8, encoding: [*c]const u8, options: c_int) c_int;
pub extern fn xmlReaderNewMemory(reader: xmlTextReaderPtr, buffer: [*c]const u8, size: c_int, URL: [*c]const u8, encoding: [*c]const u8, options: c_int) c_int;
pub extern fn xmlReaderNewFd(reader: xmlTextReaderPtr, fd: c_int, URL: [*c]const u8, encoding: [*c]const u8, options: c_int) c_int;
pub extern fn xmlReaderNewIO(reader: xmlTextReaderPtr, ioread: xmlInputReadCallback, ioclose: xmlInputCloseCallback, ioctx: ?*anyopaque, URL: [*c]const u8, encoding: [*c]const u8, options: c_int) c_int;
pub const xmlTextReaderLocatorPtr = ?*anyopaque;
pub const xmlTextReaderErrorFunc = ?*const fn (?*anyopaque, [*c]const u8, xmlParserSeverities, xmlTextReaderLocatorPtr) callconv(.c) void;
pub extern fn xmlTextReaderLocatorLineNumber(locator: xmlTextReaderLocatorPtr) c_int;
pub extern fn xmlTextReaderLocatorBaseURI(locator: xmlTextReaderLocatorPtr) [*c]xmlChar;
pub extern fn xmlTextReaderSetErrorHandler(reader: xmlTextReaderPtr, f: xmlTextReaderErrorFunc, arg: ?*anyopaque) void;
pub extern fn xmlTextReaderSetStructuredErrorHandler(reader: xmlTextReaderPtr, f: xmlStructuredErrorFunc, arg: ?*anyopaque) void;
pub extern fn xmlTextReaderGetErrorHandler(reader: xmlTextReaderPtr, f: [*c]xmlTextReaderErrorFunc, arg: [*c]?*anyopaque) void;
pub const __llvm__ = @as(c_int, 1);
pub const __clang__ = @as(c_int, 1);
pub const __clang_major__ = @as(c_int, 20);
pub const __clang_minor__ = @as(c_int, 1);
pub const __clang_patchlevel__ = @as(c_int, 2);
pub const __clang_version__ = "20.1.2 (https://github.com/ziglang/zig-bootstrap c6bc9398c72c7a63fe9420a9055dcfd1845bc266)";
pub const __GNUC__ = @as(c_int, 4);
pub const __GNUC_MINOR__ = @as(c_int, 2);
pub const __GNUC_PATCHLEVEL__ = @as(c_int, 1);
pub const __GXX_ABI_VERSION = @as(c_int, 1002);
pub const __ATOMIC_RELAXED = @as(c_int, 0);
pub const __ATOMIC_CONSUME = @as(c_int, 1);
pub const __ATOMIC_ACQUIRE = @as(c_int, 2);
pub const __ATOMIC_RELEASE = @as(c_int, 3);
pub const __ATOMIC_ACQ_REL = @as(c_int, 4);
pub const __ATOMIC_SEQ_CST = @as(c_int, 5);
pub const __MEMORY_SCOPE_SYSTEM = @as(c_int, 0);
pub const __MEMORY_SCOPE_DEVICE = @as(c_int, 1);
pub const __MEMORY_SCOPE_WRKGRP = @as(c_int, 2);
pub const __MEMORY_SCOPE_WVFRNT = @as(c_int, 3);
pub const __MEMORY_SCOPE_SINGLE = @as(c_int, 4);
pub const __OPENCL_MEMORY_SCOPE_WORK_ITEM = @as(c_int, 0);
pub const __OPENCL_MEMORY_SCOPE_WORK_GROUP = @as(c_int, 1);
pub const __OPENCL_MEMORY_SCOPE_DEVICE = @as(c_int, 2);
pub const __OPENCL_MEMORY_SCOPE_ALL_SVM_DEVICES = @as(c_int, 3);
pub const __OPENCL_MEMORY_SCOPE_SUB_GROUP = @as(c_int, 4);
pub const __FPCLASS_SNAN = @as(c_int, 0x0001);
pub const __FPCLASS_QNAN = @as(c_int, 0x0002);
pub const __FPCLASS_NEGINF = @as(c_int, 0x0004);
pub const __FPCLASS_NEGNORMAL = @as(c_int, 0x0008);
pub const __FPCLASS_NEGSUBNORMAL = @as(c_int, 0x0010);
pub const __FPCLASS_NEGZERO = @as(c_int, 0x0020);
pub const __FPCLASS_POSZERO = @as(c_int, 0x0040);
pub const __FPCLASS_POSSUBNORMAL = @as(c_int, 0x0080);
pub const __FPCLASS_POSNORMAL = @as(c_int, 0x0100);
pub const __FPCLASS_POSINF = @as(c_int, 0x0200);
pub const __PRAGMA_REDEFINE_EXTNAME = @as(c_int, 1);
pub const __VERSION__ = "Clang 20.1.2 (https://github.com/ziglang/zig-bootstrap c6bc9398c72c7a63fe9420a9055dcfd1845bc266)";
pub const __GXX_TYPEINFO_EQUALITY_INLINE = @as(c_int, 0);
pub const __OBJC_BOOL_IS_BOOL = @as(c_int, 0);
pub const __CONSTANT_CFSTRINGS__ = @as(c_int, 1);
pub const __SEH__ = @as(c_int, 1);
pub const __clang_literal_encoding__ = "UTF-8";
pub const __clang_wide_literal_encoding__ = "UTF-16";
pub const __OPTIMIZE__ = @as(c_int, 1);
pub const __ORDER_LITTLE_ENDIAN__ = @as(c_int, 1234);
pub const __ORDER_BIG_ENDIAN__ = @as(c_int, 4321);
pub const __ORDER_PDP_ENDIAN__ = @as(c_int, 3412);
pub const __BYTE_ORDER__ = __ORDER_LITTLE_ENDIAN__;
pub const __LITTLE_ENDIAN__ = @as(c_int, 1);
pub const __CHAR_BIT__ = @as(c_int, 8);
pub const __BOOL_WIDTH__ = @as(c_int, 1);
pub const __SHRT_WIDTH__ = @as(c_int, 16);
pub const __INT_WIDTH__ = @as(c_int, 32);
pub const __LONG_WIDTH__ = @as(c_int, 32);
pub const __LLONG_WIDTH__ = @as(c_int, 64);
pub const __BITINT_MAXWIDTH__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 8388608, .decimal);
pub const __SCHAR_MAX__ = @as(c_int, 127);
pub const __SHRT_MAX__ = @as(c_int, 32767);
pub const __INT_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __LONG_MAX__ = @as(c_long, 2147483647);
pub const __LONG_LONG_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __WCHAR_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 65535, .decimal);
pub const __WCHAR_WIDTH__ = @as(c_int, 16);
pub const __WINT_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 65535, .decimal);
pub const __WINT_WIDTH__ = @as(c_int, 16);
pub const __INTMAX_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __INTMAX_WIDTH__ = @as(c_int, 64);
pub const __SIZE_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const __SIZE_WIDTH__ = @as(c_int, 64);
pub const __UINTMAX_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const __UINTMAX_WIDTH__ = @as(c_int, 64);
pub const __PTRDIFF_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __PTRDIFF_WIDTH__ = @as(c_int, 64);
pub const __INTPTR_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __INTPTR_WIDTH__ = @as(c_int, 64);
pub const __UINTPTR_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const __UINTPTR_WIDTH__ = @as(c_int, 64);
pub const __SIZEOF_DOUBLE__ = @as(c_int, 8);
pub const __SIZEOF_FLOAT__ = @as(c_int, 4);
pub const __SIZEOF_INT__ = @as(c_int, 4);
pub const __SIZEOF_LONG__ = @as(c_int, 4);
pub const __SIZEOF_LONG_DOUBLE__ = @as(c_int, 16);
pub const __SIZEOF_LONG_LONG__ = @as(c_int, 8);
pub const __SIZEOF_POINTER__ = @as(c_int, 8);
pub const __SIZEOF_SHORT__ = @as(c_int, 2);
pub const __SIZEOF_PTRDIFF_T__ = @as(c_int, 8);
pub const __SIZEOF_SIZE_T__ = @as(c_int, 8);
pub const __SIZEOF_WCHAR_T__ = @as(c_int, 2);
pub const __SIZEOF_WINT_T__ = @as(c_int, 2);
pub const __SIZEOF_INT128__ = @as(c_int, 16);
pub const __INTMAX_TYPE__ = c_longlong;
pub const __INTMAX_FMTd__ = "lld";
pub const __INTMAX_FMTi__ = "lli";
pub const __INTMAX_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `LL`");
// (no file):96:9
pub const __INTMAX_C = @import("std").zig.c_translation.Macros.LL_SUFFIX;
pub const __UINTMAX_TYPE__ = c_ulonglong;
pub const __UINTMAX_FMTo__ = "llo";
pub const __UINTMAX_FMTu__ = "llu";
pub const __UINTMAX_FMTx__ = "llx";
pub const __UINTMAX_FMTX__ = "llX";
pub const __UINTMAX_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `ULL`");
// (no file):103:9
pub const __UINTMAX_C = @import("std").zig.c_translation.Macros.ULL_SUFFIX;
pub const __PTRDIFF_TYPE__ = c_longlong;
pub const __PTRDIFF_FMTd__ = "lld";
pub const __PTRDIFF_FMTi__ = "lli";
pub const __INTPTR_TYPE__ = c_longlong;
pub const __INTPTR_FMTd__ = "lld";
pub const __INTPTR_FMTi__ = "lli";
pub const __SIZE_TYPE__ = c_ulonglong;
pub const __SIZE_FMTo__ = "llo";
pub const __SIZE_FMTu__ = "llu";
pub const __SIZE_FMTx__ = "llx";
pub const __SIZE_FMTX__ = "llX";
pub const __WCHAR_TYPE__ = c_ushort;
pub const __WINT_TYPE__ = c_ushort;
pub const __SIG_ATOMIC_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __SIG_ATOMIC_WIDTH__ = @as(c_int, 32);
pub const __CHAR16_TYPE__ = c_ushort;
pub const __CHAR32_TYPE__ = c_uint;
pub const __UINTPTR_TYPE__ = c_ulonglong;
pub const __UINTPTR_FMTo__ = "llo";
pub const __UINTPTR_FMTu__ = "llu";
pub const __UINTPTR_FMTx__ = "llx";
pub const __UINTPTR_FMTX__ = "llX";
pub const __FLT16_DENORM_MIN__ = @as(f16, 5.9604644775390625e-8);
pub const __FLT16_NORM_MAX__ = @as(f16, 6.5504e+4);
pub const __FLT16_HAS_DENORM__ = @as(c_int, 1);
pub const __FLT16_DIG__ = @as(c_int, 3);
pub const __FLT16_DECIMAL_DIG__ = @as(c_int, 5);
pub const __FLT16_EPSILON__ = @as(f16, 9.765625e-4);
pub const __FLT16_HAS_INFINITY__ = @as(c_int, 1);
pub const __FLT16_HAS_QUIET_NAN__ = @as(c_int, 1);
pub const __FLT16_MANT_DIG__ = @as(c_int, 11);
pub const __FLT16_MAX_10_EXP__ = @as(c_int, 4);
pub const __FLT16_MAX_EXP__ = @as(c_int, 16);
pub const __FLT16_MAX__ = @as(f16, 6.5504e+4);
pub const __FLT16_MIN_10_EXP__ = -@as(c_int, 4);
pub const __FLT16_MIN_EXP__ = -@as(c_int, 13);
pub const __FLT16_MIN__ = @as(f16, 6.103515625e-5);
pub const __FLT_DENORM_MIN__ = @as(f32, 1.40129846e-45);
pub const __FLT_NORM_MAX__ = @as(f32, 3.40282347e+38);
pub const __FLT_HAS_DENORM__ = @as(c_int, 1);
pub const __FLT_DIG__ = @as(c_int, 6);
pub const __FLT_DECIMAL_DIG__ = @as(c_int, 9);
pub const __FLT_EPSILON__ = @as(f32, 1.19209290e-7);
pub const __FLT_HAS_INFINITY__ = @as(c_int, 1);
pub const __FLT_HAS_QUIET_NAN__ = @as(c_int, 1);
pub const __FLT_MANT_DIG__ = @as(c_int, 24);
pub const __FLT_MAX_10_EXP__ = @as(c_int, 38);
pub const __FLT_MAX_EXP__ = @as(c_int, 128);
pub const __FLT_MAX__ = @as(f32, 3.40282347e+38);
pub const __FLT_MIN_10_EXP__ = -@as(c_int, 37);
pub const __FLT_MIN_EXP__ = -@as(c_int, 125);
pub const __FLT_MIN__ = @as(f32, 1.17549435e-38);
pub const __DBL_DENORM_MIN__ = @as(f64, 4.9406564584124654e-324);
pub const __DBL_NORM_MAX__ = @as(f64, 1.7976931348623157e+308);
pub const __DBL_HAS_DENORM__ = @as(c_int, 1);
pub const __DBL_DIG__ = @as(c_int, 15);
pub const __DBL_DECIMAL_DIG__ = @as(c_int, 17);
pub const __DBL_EPSILON__ = @as(f64, 2.2204460492503131e-16);
pub const __DBL_HAS_INFINITY__ = @as(c_int, 1);
pub const __DBL_HAS_QUIET_NAN__ = @as(c_int, 1);
pub const __DBL_MANT_DIG__ = @as(c_int, 53);
pub const __DBL_MAX_10_EXP__ = @as(c_int, 308);
pub const __DBL_MAX_EXP__ = @as(c_int, 1024);
pub const __DBL_MAX__ = @as(f64, 1.7976931348623157e+308);
pub const __DBL_MIN_10_EXP__ = -@as(c_int, 307);
pub const __DBL_MIN_EXP__ = -@as(c_int, 1021);
pub const __DBL_MIN__ = @as(f64, 2.2250738585072014e-308);
pub const __LDBL_DENORM_MIN__ = @as(c_longdouble, 3.64519953188247460253e-4951);
pub const __LDBL_NORM_MAX__ = @as(c_longdouble, 1.18973149535723176502e+4932);
pub const __LDBL_HAS_DENORM__ = @as(c_int, 1);
pub const __LDBL_DIG__ = @as(c_int, 18);
pub const __LDBL_DECIMAL_DIG__ = @as(c_int, 21);
pub const __LDBL_EPSILON__ = @as(c_longdouble, 1.08420217248550443401e-19);
pub const __LDBL_HAS_INFINITY__ = @as(c_int, 1);
pub const __LDBL_HAS_QUIET_NAN__ = @as(c_int, 1);
pub const __LDBL_MANT_DIG__ = @as(c_int, 64);
pub const __LDBL_MAX_10_EXP__ = @as(c_int, 4932);
pub const __LDBL_MAX_EXP__ = @as(c_int, 16384);
pub const __LDBL_MAX__ = @as(c_longdouble, 1.18973149535723176502e+4932);
pub const __LDBL_MIN_10_EXP__ = -@as(c_int, 4931);
pub const __LDBL_MIN_EXP__ = -@as(c_int, 16381);
pub const __LDBL_MIN__ = @as(c_longdouble, 3.36210314311209350626e-4932);
pub const __POINTER_WIDTH__ = @as(c_int, 64);
pub const __BIGGEST_ALIGNMENT__ = @as(c_int, 16);
pub const __WCHAR_UNSIGNED__ = @as(c_int, 1);
pub const __WINT_UNSIGNED__ = @as(c_int, 1);
pub const __INT8_TYPE__ = i8;
pub const __INT8_FMTd__ = "hhd";
pub const __INT8_FMTi__ = "hhi";
pub const __INT8_C_SUFFIX__ = "";
pub inline fn __INT8_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const __INT16_TYPE__ = c_short;
pub const __INT16_FMTd__ = "hd";
pub const __INT16_FMTi__ = "hi";
pub const __INT16_C_SUFFIX__ = "";
pub inline fn __INT16_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const __INT32_TYPE__ = c_int;
pub const __INT32_FMTd__ = "d";
pub const __INT32_FMTi__ = "i";
pub const __INT32_C_SUFFIX__ = "";
pub inline fn __INT32_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const __INT64_TYPE__ = c_longlong;
pub const __INT64_FMTd__ = "lld";
pub const __INT64_FMTi__ = "lli";
pub const __INT64_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `LL`");
// (no file):209:9
pub const __INT64_C = @import("std").zig.c_translation.Macros.LL_SUFFIX;
pub const __UINT8_TYPE__ = u8;
pub const __UINT8_FMTo__ = "hho";
pub const __UINT8_FMTu__ = "hhu";
pub const __UINT8_FMTx__ = "hhx";
pub const __UINT8_FMTX__ = "hhX";
pub const __UINT8_C_SUFFIX__ = "";
pub inline fn __UINT8_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const __UINT8_MAX__ = @as(c_int, 255);
pub const __INT8_MAX__ = @as(c_int, 127);
pub const __UINT16_TYPE__ = c_ushort;
pub const __UINT16_FMTo__ = "ho";
pub const __UINT16_FMTu__ = "hu";
pub const __UINT16_FMTx__ = "hx";
pub const __UINT16_FMTX__ = "hX";
pub const __UINT16_C_SUFFIX__ = "";
pub inline fn __UINT16_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const __UINT16_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 65535, .decimal);
pub const __INT16_MAX__ = @as(c_int, 32767);
pub const __UINT32_TYPE__ = c_uint;
pub const __UINT32_FMTo__ = "o";
pub const __UINT32_FMTu__ = "u";
pub const __UINT32_FMTx__ = "x";
pub const __UINT32_FMTX__ = "X";
pub const __UINT32_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `U`");
// (no file):234:9
pub const __UINT32_C = @import("std").zig.c_translation.Macros.U_SUFFIX;
pub const __UINT32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __INT32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __UINT64_TYPE__ = c_ulonglong;
pub const __UINT64_FMTo__ = "llo";
pub const __UINT64_FMTu__ = "llu";
pub const __UINT64_FMTx__ = "llx";
pub const __UINT64_FMTX__ = "llX";
pub const __UINT64_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `ULL`");
// (no file):243:9
pub const __UINT64_C = @import("std").zig.c_translation.Macros.ULL_SUFFIX;
pub const __UINT64_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const __INT64_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __INT_LEAST8_TYPE__ = i8;
pub const __INT_LEAST8_MAX__ = @as(c_int, 127);
pub const __INT_LEAST8_WIDTH__ = @as(c_int, 8);
pub const __INT_LEAST8_FMTd__ = "hhd";
pub const __INT_LEAST8_FMTi__ = "hhi";
pub const __UINT_LEAST8_TYPE__ = u8;
pub const __UINT_LEAST8_MAX__ = @as(c_int, 255);
pub const __UINT_LEAST8_FMTo__ = "hho";
pub const __UINT_LEAST8_FMTu__ = "hhu";
pub const __UINT_LEAST8_FMTx__ = "hhx";
pub const __UINT_LEAST8_FMTX__ = "hhX";
pub const __INT_LEAST16_TYPE__ = c_short;
pub const __INT_LEAST16_MAX__ = @as(c_int, 32767);
pub const __INT_LEAST16_WIDTH__ = @as(c_int, 16);
pub const __INT_LEAST16_FMTd__ = "hd";
pub const __INT_LEAST16_FMTi__ = "hi";
pub const __UINT_LEAST16_TYPE__ = c_ushort;
pub const __UINT_LEAST16_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 65535, .decimal);
pub const __UINT_LEAST16_FMTo__ = "ho";
pub const __UINT_LEAST16_FMTu__ = "hu";
pub const __UINT_LEAST16_FMTx__ = "hx";
pub const __UINT_LEAST16_FMTX__ = "hX";
pub const __INT_LEAST32_TYPE__ = c_int;
pub const __INT_LEAST32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __INT_LEAST32_WIDTH__ = @as(c_int, 32);
pub const __INT_LEAST32_FMTd__ = "d";
pub const __INT_LEAST32_FMTi__ = "i";
pub const __UINT_LEAST32_TYPE__ = c_uint;
pub const __UINT_LEAST32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __UINT_LEAST32_FMTo__ = "o";
pub const __UINT_LEAST32_FMTu__ = "u";
pub const __UINT_LEAST32_FMTx__ = "x";
pub const __UINT_LEAST32_FMTX__ = "X";
pub const __INT_LEAST64_TYPE__ = c_longlong;
pub const __INT_LEAST64_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __INT_LEAST64_WIDTH__ = @as(c_int, 64);
pub const __INT_LEAST64_FMTd__ = "lld";
pub const __INT_LEAST64_FMTi__ = "lli";
pub const __UINT_LEAST64_TYPE__ = c_ulonglong;
pub const __UINT_LEAST64_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const __UINT_LEAST64_FMTo__ = "llo";
pub const __UINT_LEAST64_FMTu__ = "llu";
pub const __UINT_LEAST64_FMTx__ = "llx";
pub const __UINT_LEAST64_FMTX__ = "llX";
pub const __INT_FAST8_TYPE__ = i8;
pub const __INT_FAST8_MAX__ = @as(c_int, 127);
pub const __INT_FAST8_WIDTH__ = @as(c_int, 8);
pub const __INT_FAST8_FMTd__ = "hhd";
pub const __INT_FAST8_FMTi__ = "hhi";
pub const __UINT_FAST8_TYPE__ = u8;
pub const __UINT_FAST8_MAX__ = @as(c_int, 255);
pub const __UINT_FAST8_FMTo__ = "hho";
pub const __UINT_FAST8_FMTu__ = "hhu";
pub const __UINT_FAST8_FMTx__ = "hhx";
pub const __UINT_FAST8_FMTX__ = "hhX";
pub const __INT_FAST16_TYPE__ = c_short;
pub const __INT_FAST16_MAX__ = @as(c_int, 32767);
pub const __INT_FAST16_WIDTH__ = @as(c_int, 16);
pub const __INT_FAST16_FMTd__ = "hd";
pub const __INT_FAST16_FMTi__ = "hi";
pub const __UINT_FAST16_TYPE__ = c_ushort;
pub const __UINT_FAST16_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 65535, .decimal);
pub const __UINT_FAST16_FMTo__ = "ho";
pub const __UINT_FAST16_FMTu__ = "hu";
pub const __UINT_FAST16_FMTx__ = "hx";
pub const __UINT_FAST16_FMTX__ = "hX";
pub const __INT_FAST32_TYPE__ = c_int;
pub const __INT_FAST32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __INT_FAST32_WIDTH__ = @as(c_int, 32);
pub const __INT_FAST32_FMTd__ = "d";
pub const __INT_FAST32_FMTi__ = "i";
pub const __UINT_FAST32_TYPE__ = c_uint;
pub const __UINT_FAST32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __UINT_FAST32_FMTo__ = "o";
pub const __UINT_FAST32_FMTu__ = "u";
pub const __UINT_FAST32_FMTx__ = "x";
pub const __UINT_FAST32_FMTX__ = "X";
pub const __INT_FAST64_TYPE__ = c_longlong;
pub const __INT_FAST64_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __INT_FAST64_WIDTH__ = @as(c_int, 64);
pub const __INT_FAST64_FMTd__ = "lld";
pub const __INT_FAST64_FMTi__ = "lli";
pub const __UINT_FAST64_TYPE__ = c_ulonglong;
pub const __UINT_FAST64_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const __UINT_FAST64_FMTo__ = "llo";
pub const __UINT_FAST64_FMTu__ = "llu";
pub const __UINT_FAST64_FMTx__ = "llx";
pub const __UINT_FAST64_FMTX__ = "llX";
pub const __USER_LABEL_PREFIX__ = "";
pub const __FINITE_MATH_ONLY__ = @as(c_int, 0);
pub const __GNUC_STDC_INLINE__ = @as(c_int, 1);
pub const __GCC_ATOMIC_TEST_AND_SET_TRUEVAL = @as(c_int, 1);
pub const __GCC_DESTRUCTIVE_SIZE = @as(c_int, 64);
pub const __GCC_CONSTRUCTIVE_SIZE = @as(c_int, 64);
pub const __CLANG_ATOMIC_BOOL_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_CHAR_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_CHAR16_T_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_CHAR32_T_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_WCHAR_T_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_SHORT_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_INT_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_LONG_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_LLONG_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_POINTER_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_BOOL_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_CHAR_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_CHAR16_T_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_CHAR32_T_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_WCHAR_T_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_SHORT_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_INT_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_LONG_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_LLONG_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_POINTER_LOCK_FREE = @as(c_int, 2);
pub const __PIC__ = @as(c_int, 2);
pub const __pic__ = @as(c_int, 2);
pub const __FLT_RADIX__ = @as(c_int, 2);
pub const __DECIMAL_DIG__ = __LDBL_DECIMAL_DIG__;
pub const __SSP_STRONG__ = @as(c_int, 2);
pub const __GCC_ASM_FLAG_OUTPUTS__ = @as(c_int, 1);
pub const __code_model_small__ = @as(c_int, 1);
pub const __amd64__ = @as(c_int, 1);
pub const __amd64 = @as(c_int, 1);
pub const __x86_64 = @as(c_int, 1);
pub const __x86_64__ = @as(c_int, 1);
pub const __SEG_GS = @as(c_int, 1);
pub const __SEG_FS = @as(c_int, 1);
pub const __seg_gs = @compileError("unable to translate macro: undefined identifier `address_space`");
// (no file):376:9
pub const __seg_fs = @compileError("unable to translate macro: undefined identifier `address_space`");
// (no file):377:9
pub const __corei7 = @as(c_int, 1);
pub const __corei7__ = @as(c_int, 1);
pub const __tune_corei7__ = @as(c_int, 1);
pub const __REGISTER_PREFIX__ = "";
pub const __NO_MATH_INLINES = @as(c_int, 1);
pub const __AES__ = @as(c_int, 1);
pub const __VAES__ = @as(c_int, 1);
pub const __PCLMUL__ = @as(c_int, 1);
pub const __VPCLMULQDQ__ = @as(c_int, 1);
pub const __LAHF_SAHF__ = @as(c_int, 1);
pub const __LZCNT__ = @as(c_int, 1);
pub const __RDRND__ = @as(c_int, 1);
pub const __FSGSBASE__ = @as(c_int, 1);
pub const __BMI__ = @as(c_int, 1);
pub const __BMI2__ = @as(c_int, 1);
pub const __POPCNT__ = @as(c_int, 1);
pub const __PRFCHW__ = @as(c_int, 1);
pub const __RDSEED__ = @as(c_int, 1);
pub const __ADX__ = @as(c_int, 1);
pub const __MOVBE__ = @as(c_int, 1);
pub const __FMA__ = @as(c_int, 1);
pub const __F16C__ = @as(c_int, 1);
pub const __GFNI__ = @as(c_int, 1);
pub const __EVEX512__ = @as(c_int, 1);
pub const __AVX512CD__ = @as(c_int, 1);
pub const __AVX512VPOPCNTDQ__ = @as(c_int, 1);
pub const __AVX512VNNI__ = @as(c_int, 1);
pub const __AVX512DQ__ = @as(c_int, 1);
pub const __AVX512BITALG__ = @as(c_int, 1);
pub const __AVX512BW__ = @as(c_int, 1);
pub const __AVX512VL__ = @as(c_int, 1);
pub const __EVEX256__ = @as(c_int, 1);
pub const __AVX512VBMI__ = @as(c_int, 1);
pub const __AVX512VBMI2__ = @as(c_int, 1);
pub const __AVX512IFMA__ = @as(c_int, 1);
pub const __AVX512VP2INTERSECT__ = @as(c_int, 1);
pub const __SHA__ = @as(c_int, 1);
pub const __FXSR__ = @as(c_int, 1);
pub const __XSAVE__ = @as(c_int, 1);
pub const __XSAVEOPT__ = @as(c_int, 1);
pub const __XSAVEC__ = @as(c_int, 1);
pub const __XSAVES__ = @as(c_int, 1);
pub const __CLFLUSHOPT__ = @as(c_int, 1);
pub const __CLWB__ = @as(c_int, 1);
pub const __SHSTK__ = @as(c_int, 1);
pub const __KL__ = @as(c_int, 1);
pub const __WIDEKL__ = @as(c_int, 1);
pub const __RDPID__ = @as(c_int, 1);
pub const __MOVDIRI__ = @as(c_int, 1);
pub const __MOVDIR64B__ = @as(c_int, 1);
pub const __INVPCID__ = @as(c_int, 1);
pub const __CRC32__ = @as(c_int, 1);
pub const __AVX512F__ = @as(c_int, 1);
pub const __AVX2__ = @as(c_int, 1);
pub const __AVX__ = @as(c_int, 1);
pub const __SSE4_2__ = @as(c_int, 1);
pub const __SSE4_1__ = @as(c_int, 1);
pub const __SSSE3__ = @as(c_int, 1);
pub const __SSE3__ = @as(c_int, 1);
pub const __SSE2__ = @as(c_int, 1);
pub const __SSE2_MATH__ = @as(c_int, 1);
pub const __SSE__ = @as(c_int, 1);
pub const __SSE_MATH__ = @as(c_int, 1);
pub const __MMX__ = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_1 = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_2 = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_4 = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_8 = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_16 = @as(c_int, 1);
pub const __SIZEOF_FLOAT128__ = @as(c_int, 16);
pub const _WIN32 = @as(c_int, 1);
pub const _WIN64 = @as(c_int, 1);
pub const WIN32 = @as(c_int, 1);
pub const __WIN32 = @as(c_int, 1);
pub const __WIN32__ = @as(c_int, 1);
pub const WINNT = @as(c_int, 1);
pub const __WINNT = @as(c_int, 1);
pub const __WINNT__ = @as(c_int, 1);
pub const WIN64 = @as(c_int, 1);
pub const __WIN64 = @as(c_int, 1);
pub const __WIN64__ = @as(c_int, 1);
pub const __MINGW64__ = @as(c_int, 1);
pub const __MSVCRT__ = @as(c_int, 1);
pub const __MINGW32__ = @as(c_int, 1);
pub const __declspec = @compileError("unable to translate C expr: unexpected token '__attribute__'");
// (no file):462:9
pub const _cdecl = @compileError("unable to translate macro: undefined identifier `__cdecl__`");
// (no file):463:9
pub const __cdecl = @compileError("unable to translate macro: undefined identifier `__cdecl__`");
// (no file):464:9
pub const _stdcall = @compileError("unable to translate macro: undefined identifier `__stdcall__`");
// (no file):465:9
pub const __stdcall = @compileError("unable to translate macro: undefined identifier `__stdcall__`");
// (no file):466:9
pub const _fastcall = @compileError("unable to translate macro: undefined identifier `__fastcall__`");
// (no file):467:9
pub const __fastcall = @compileError("unable to translate macro: undefined identifier `__fastcall__`");
// (no file):468:9
pub const _thiscall = @compileError("unable to translate macro: undefined identifier `__thiscall__`");
// (no file):469:9
pub const __thiscall = @compileError("unable to translate macro: undefined identifier `__thiscall__`");
// (no file):470:9
pub const _pascal = @compileError("unable to translate macro: undefined identifier `__pascal__`");
// (no file):471:9
pub const __pascal = @compileError("unable to translate macro: undefined identifier `__pascal__`");
// (no file):472:9
pub const __STDC__ = @as(c_int, 1);
pub const __STDC_HOSTED__ = @as(c_int, 1);
pub const __STDC_VERSION__ = @as(c_long, 201710);
pub const __STDC_UTF_16__ = @as(c_int, 1);
pub const __STDC_UTF_32__ = @as(c_int, 1);
pub const __STDC_EMBED_NOT_FOUND__ = @as(c_int, 0);
pub const __STDC_EMBED_FOUND__ = @as(c_int, 1);
pub const __STDC_EMBED_EMPTY__ = @as(c_int, 2);
pub const _FORTIFY_SOURCE = @as(c_int, 2);
pub const __MSVCRT_VERSION__ = @as(c_int, 0xE00);
pub const _WIN32_WINNT = @as(c_int, 0x0a00);
pub const LIBXML_TREE_ENABLED = "";
pub const LIBXML_SCHEMAS_ENABLED = "";
pub const LIBXML_READER_ENABLED = "";
pub const __XML_XMLREADER_H__ = "";
pub const __XML_VERSION_H__ = "";
pub const __XML_EXPORTS_H__ = "";
pub const XMLPUBLIC = @compileError("unable to translate macro: undefined identifier `dllimport`");
// .zig-cache\o\d7601404d236499ce55c245150822482/libxml/xmlexports.h:18:13
pub const XMLPUBFUN = XMLPUBLIC;
pub const XMLPUBVAR = @compileError("unable to translate C expr: unexpected token 'extern'");
// .zig-cache\o\d7601404d236499ce55c245150822482/libxml/xmlexports.h:37:9
pub const XMLCALL = "";
pub const XMLCDECL = "";
pub const LIBXML_DLL_IMPORT = XMLPUBVAR;
pub const XML_IGNORE_FPTR_CAST_WARNINGS = "";
pub const XML_POP_WARNINGS = "";
pub const LIBXML_ATTR_FORMAT = @compileError("unable to translate C expr: unexpected token ''");
// .zig-cache\o\d7601404d236499ce55c245150822482/libxml/xmlversion.h:13:9
pub const LIBXML_ATTR_ALLOC_SIZE = @compileError("unable to translate C expr: unexpected token ''");
// .zig-cache\o\d7601404d236499ce55c245150822482/libxml/xmlversion.h:14:9
pub const ATTRIBUTE_UNUSED = "";
pub const XML_DEPRECATED = "";
pub const __XML_TREE_H__ = "";
pub const _INC_STDIO = "";
pub const _STDIO_CONFIG_DEFINED = "";
pub const _INC_CORECRT = "";
pub const _INC__MINGW_H = "";
pub const _INC_CRTDEFS_MACRO = "";
pub const __MINGW64_PASTE2 = @compileError("unable to translate C expr: unexpected token '##'");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw_mac.h:10:9
pub inline fn __MINGW64_PASTE(x: anytype, y: anytype) @TypeOf(__MINGW64_PASTE2(x, y)) {
    _ = &x;
    _ = &y;
    return __MINGW64_PASTE2(x, y);
}
pub const __STRINGIFY = @compileError("unable to translate C expr: unexpected token '#'");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw_mac.h:13:9
pub inline fn __MINGW64_STRINGIFY(x: anytype) @TypeOf(__STRINGIFY(x)) {
    _ = &x;
    return __STRINGIFY(x);
}
pub const __MINGW64_VERSION_MAJOR = @as(c_int, 13);
pub const __MINGW64_VERSION_MINOR = @as(c_int, 0);
pub const __MINGW64_VERSION_BUGFIX = @as(c_int, 0);
pub const __MINGW64_VERSION_RC = @as(c_int, 0);
pub const __MINGW64_VERSION_STR = __MINGW64_STRINGIFY(__MINGW64_VERSION_MAJOR) ++ "." ++ __MINGW64_STRINGIFY(__MINGW64_VERSION_MINOR) ++ "." ++ __MINGW64_STRINGIFY(__MINGW64_VERSION_BUGFIX);
pub const __MINGW64_VERSION_STATE = "alpha";
pub const __MINGW32_MAJOR_VERSION = @as(c_int, 3);
pub const __MINGW32_MINOR_VERSION = @as(c_int, 11);
pub const _M_AMD64 = @as(c_int, 100);
pub const _M_X64 = @as(c_int, 100);
pub const @"_" = @as(c_int, 1);
pub const __MINGW_USE_UNDERSCORE_PREFIX = @as(c_int, 0);
pub const __MINGW_IMP_SYMBOL = @compileError("unable to translate macro: undefined identifier `__imp_`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw_mac.h:129:11
pub const __MINGW_IMP_LSYMBOL = @compileError("unable to translate macro: undefined identifier `__imp_`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw_mac.h:130:11
pub inline fn __MINGW_USYMBOL(sym: anytype) @TypeOf(sym) {
    _ = &sym;
    return sym;
}
pub inline fn __MINGW_LSYMBOL(sym: anytype) @TypeOf(__MINGW64_PASTE(@"_", sym)) {
    _ = &sym;
    return __MINGW64_PASTE(@"_", sym);
}
pub const __MINGW_ASM_CALL = @compileError("unable to translate C expr: unexpected token '__asm__'");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw_mac.h:140:9
pub const __MINGW_ASM_CRT_CALL = @compileError("unable to translate C expr: unexpected token '__asm__'");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw_mac.h:141:9
pub const __MINGW_EXTENSION = @compileError("unable to translate C expr: unexpected token '__extension__'");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw_mac.h:173:13
pub const __C89_NAMELESS = __MINGW_EXTENSION;
pub const __C89_NAMELESSSTRUCTNAME = "";
pub const __C89_NAMELESSSTRUCTNAME1 = "";
pub const __C89_NAMELESSSTRUCTNAME2 = "";
pub const __C89_NAMELESSSTRUCTNAME3 = "";
pub const __C89_NAMELESSSTRUCTNAME4 = "";
pub const __C89_NAMELESSSTRUCTNAME5 = "";
pub const __C89_NAMELESSUNIONNAME = "";
pub const __C89_NAMELESSUNIONNAME1 = "";
pub const __C89_NAMELESSUNIONNAME2 = "";
pub const __C89_NAMELESSUNIONNAME3 = "";
pub const __C89_NAMELESSUNIONNAME4 = "";
pub const __C89_NAMELESSUNIONNAME5 = "";
pub const __C89_NAMELESSUNIONNAME6 = "";
pub const __C89_NAMELESSUNIONNAME7 = "";
pub const __C89_NAMELESSUNIONNAME8 = "";
pub const __GNU_EXTENSION = __MINGW_EXTENSION;
pub const __MINGW_HAVE_ANSI_C99_PRINTF = @as(c_int, 1);
pub const __MINGW_HAVE_WIDE_C99_PRINTF = @as(c_int, 1);
pub const __MINGW_HAVE_ANSI_C99_SCANF = @as(c_int, 1);
pub const __MINGW_HAVE_WIDE_C99_SCANF = @as(c_int, 1);
pub const __MINGW_POISON_NAME = @compileError("unable to translate macro: undefined identifier `_layout_has_not_been_verified_and_its_declaration_is_most_likely_incorrect`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw_mac.h:213:11
pub const __MSABI_LONG = @import("std").zig.c_translation.Macros.L_SUFFIX;
pub const __MINGW_GCC_VERSION = ((__GNUC__ * @as(c_int, 10000)) + (__GNUC_MINOR__ * @as(c_int, 100))) + __GNUC_PATCHLEVEL__;
pub inline fn __MINGW_GNUC_PREREQ(major: anytype, minor: anytype) @TypeOf((__GNUC__ > major) or ((__GNUC__ == major) and (__GNUC_MINOR__ >= minor))) {
    _ = &major;
    _ = &minor;
    return (__GNUC__ > major) or ((__GNUC__ == major) and (__GNUC_MINOR__ >= minor));
}
pub inline fn __MINGW_MSC_PREREQ(major: anytype, minor: anytype) @TypeOf(@as(c_int, 0)) {
    _ = &major;
    _ = &minor;
    return @as(c_int, 0);
}
pub const __MINGW_ATTRIB_DEPRECATED_STR = @compileError("unable to translate C expr: unexpected token ''");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw_mac.h:257:11
pub const __MINGW_SEC_WARN_STR = "This function or variable may be unsafe, use _CRT_SECURE_NO_WARNINGS to disable deprecation";
pub const __MINGW_MSVC2005_DEPREC_STR = "This POSIX function is deprecated beginning in Visual C++ 2005, use _CRT_NONSTDC_NO_DEPRECATE to disable deprecation";
pub const __MINGW_ATTRIB_DEPRECATED_MSVC2005 = __MINGW_ATTRIB_DEPRECATED_STR(__MINGW_MSVC2005_DEPREC_STR);
pub const __MINGW_ATTRIB_DEPRECATED_SEC_WARN = __MINGW_ATTRIB_DEPRECATED_STR(__MINGW_SEC_WARN_STR);
pub const __MINGW_MS_PRINTF = @compileError("unable to translate macro: undefined identifier `__format__`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw_mac.h:281:9
pub const __MINGW_MS_SCANF = @compileError("unable to translate macro: undefined identifier `__format__`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw_mac.h:284:9
pub const __MINGW_GNU_PRINTF = @compileError("unable to translate macro: undefined identifier `__format__`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw_mac.h:287:9
pub const __MINGW_GNU_SCANF = @compileError("unable to translate macro: undefined identifier `__format__`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw_mac.h:290:9
pub const __mingw_ovr = @compileError("unable to translate macro: undefined identifier `__unused__`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw_mac.h:311:11
pub const __mingw_attribute_artificial = @compileError("unable to translate macro: undefined identifier `__artificial__`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw_mac.h:318:11
pub const __MINGW_SELECTANY = @compileError("unable to translate macro: undefined identifier `__selectany__`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw_mac.h:324:9
pub const __MINGW_FORTIFY_LEVEL = @as(c_int, 2);
pub const __mingw_bos_declare = @compileError("unable to translate macro: undefined identifier `__noreturn__`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw_mac.h:356:11
pub inline fn __mingw_bos(p: anytype, maxtype: anytype) @TypeOf(__builtin_object_size(p, (maxtype > @as(c_int, 0)) and (__MINGW_FORTIFY_LEVEL > @as(c_int, 1)))) {
    _ = &p;
    _ = &maxtype;
    return __builtin_object_size(p, (maxtype > @as(c_int, 0)) and (__MINGW_FORTIFY_LEVEL > @as(c_int, 1)));
}
pub inline fn __mingw_bos_known(p: anytype) @TypeOf(__mingw_bos(p, @as(c_int, 0)) != @import("std").zig.c_translation.cast(usize, -@as(c_int, 1))) {
    _ = &p;
    return __mingw_bos(p, @as(c_int, 0)) != @import("std").zig.c_translation.cast(usize, -@as(c_int, 1));
}
pub inline fn __mingw_bos_cond_chk(c: anytype) @TypeOf(if (__builtin_expect(c, @as(c_int, 1))) @import("std").zig.c_translation.cast(anyopaque, @as(c_int, 0)) else __chk_fail()) {
    _ = &c;
    return if (__builtin_expect(c, @as(c_int, 1))) @import("std").zig.c_translation.cast(anyopaque, @as(c_int, 0)) else __chk_fail();
}
pub inline fn __mingw_bos_ptr_chk(p: anytype, n: anytype, maxtype: anytype) @TypeOf(__mingw_bos_cond_chk(!(__mingw_bos_known(p) != 0) or (__mingw_bos(p, maxtype) >= @import("std").zig.c_translation.cast(usize, n)))) {
    _ = &p;
    _ = &n;
    _ = &maxtype;
    return __mingw_bos_cond_chk(!(__mingw_bos_known(p) != 0) or (__mingw_bos(p, maxtype) >= @import("std").zig.c_translation.cast(usize, n)));
}
pub inline fn __mingw_bos_ptr_chk_warn(p: anytype, n: anytype, maxtype: anytype) @TypeOf(if (((__mingw_bos_known(p) != 0) and (__builtin_constant_p(__mingw_bos(p, maxtype) < @import("std").zig.c_translation.cast(usize, n)) != 0)) and (__mingw_bos(p, maxtype) < @import("std").zig.c_translation.cast(usize, n))) __mingw_chk_fail_warn() else __mingw_bos_ptr_chk(p, n, maxtype)) {
    _ = &p;
    _ = &n;
    _ = &maxtype;
    return if (((__mingw_bos_known(p) != 0) and (__builtin_constant_p(__mingw_bos(p, maxtype) < @import("std").zig.c_translation.cast(usize, n)) != 0)) and (__mingw_bos(p, maxtype) < @import("std").zig.c_translation.cast(usize, n))) __mingw_chk_fail_warn() else __mingw_bos_ptr_chk(p, n, maxtype);
}
pub const __mingw_bos_ovr = @compileError("unable to translate macro: undefined identifier `__always_inline__`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw_mac.h:382:11
pub const __mingw_bos_extern_ovr = @compileError("unable to translate macro: undefined identifier `__always_inline__`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw_mac.h:385:11
pub const __MINGW_FORTIFY_VA_ARG = @as(c_int, 0);
pub const _INC_MINGW_SECAPI = "";
pub const _CRT_SECURE_CPP_OVERLOAD_SECURE_NAMES = @as(c_int, 0);
pub const _CRT_SECURE_CPP_OVERLOAD_SECURE_NAMES_MEMORY = @as(c_int, 0);
pub const _CRT_SECURE_CPP_OVERLOAD_STANDARD_NAMES = @as(c_int, 0);
pub const _CRT_SECURE_CPP_OVERLOAD_STANDARD_NAMES_COUNT = @as(c_int, 0);
pub const _CRT_SECURE_CPP_OVERLOAD_STANDARD_NAMES_MEMORY = @as(c_int, 0);
pub const __MINGW_CRT_NAME_CONCAT2 = @compileError("unable to translate macro: undefined identifier `_s`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw_secapi.h:41:9
pub const __CRT_SECURE_CPP_OVERLOAD_STANDARD_NAMES_MEMORY_0_3_ = @compileError("unable to translate C expr: unexpected token ';'");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw_secapi.h:69:9
pub const __LONG32 = c_long;
pub const __MINGW_IMPORT = @compileError("unable to translate macro: undefined identifier `__dllimport__`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw.h:44:12
pub const __USE_CRTIMP = @as(c_int, 1);
pub const _CRTIMP = @compileError("unable to translate macro: undefined identifier `__dllimport__`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw.h:52:15
pub const __DECLSPEC_SUPPORTED = "";
pub const USE___UUIDOF = @as(c_int, 0);
pub const _inline = @compileError("unable to translate C expr: unexpected token '__inline'");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw.h:74:9
pub const __CRT_INLINE = @compileError("unable to translate macro: undefined identifier `__gnu_inline__`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw.h:83:11
pub const __MINGW_INTRIN_INLINE = @compileError("unable to translate macro: undefined identifier `__always_inline__`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw.h:90:9
pub const __MINGW_CXX11_CONSTEXPR = "";
pub const __MINGW_CXX14_CONSTEXPR = "";
pub const __UNUSED_PARAM = @compileError("unable to translate macro: undefined identifier `__unused__`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw.h:118:11
pub const __restrict_arr = @compileError("unable to translate C expr: unexpected token '__restrict'");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw.h:133:10
pub const __MINGW_ATTRIB_NORETURN = @compileError("unable to translate macro: undefined identifier `__noreturn__`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw.h:149:9
pub const __MINGW_ATTRIB_CONST = @compileError("unable to translate C expr: unexpected token '__attribute__'");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw.h:150:9
pub const __MINGW_ATTRIB_MALLOC = @compileError("unable to translate macro: undefined identifier `__malloc__`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw.h:160:9
pub const __MINGW_ATTRIB_PURE = @compileError("unable to translate macro: undefined identifier `__pure__`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw.h:161:9
pub const __MINGW_ATTRIB_NONNULL = @compileError("unable to translate macro: undefined identifier `__nonnull__`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw.h:174:9
pub const __MINGW_ATTRIB_UNUSED = @compileError("unable to translate macro: undefined identifier `__unused__`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw.h:180:9
pub const __MINGW_ATTRIB_USED = @compileError("unable to translate macro: undefined identifier `__used__`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw.h:186:9
pub const __MINGW_ATTRIB_DEPRECATED = @compileError("unable to translate macro: undefined identifier `__deprecated__`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw.h:187:9
pub const __MINGW_ATTRIB_DEPRECATED_MSG = @compileError("unable to translate macro: undefined identifier `__deprecated__`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw.h:189:9
pub const __MINGW_NOTHROW = @compileError("unable to translate macro: undefined identifier `__nothrow__`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw.h:204:9
pub const __MINGW_ATTRIB_NO_OPTIMIZE = "";
pub const __MINGW_PRAGMA_PARAM = @compileError("unable to translate C expr: unexpected token ''");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw.h:222:9
pub const __MINGW_BROKEN_INTERFACE = @compileError("unable to translate macro: undefined identifier `message`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw.h:225:9
pub const _UCRT = "";
pub inline fn __MINGW_UCRT_ASM_CALL(func: anytype) @TypeOf(__MINGW_ASM_CALL(func)) {
    _ = &func;
    return __MINGW_ASM_CALL(func);
}
pub const _INT128_DEFINED = "";
pub const __int8 = u8;
pub const __int16 = c_short;
pub const __int32 = c_int;
pub const __int64 = c_longlong;
pub const __ptr32 = "";
pub const __ptr64 = "";
pub const __unaligned = "";
pub const __w64 = "";
pub const __forceinline = @compileError("unable to translate macro: undefined identifier `__always_inline__`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw.h:290:9
pub const __nothrow = "";
pub const _INC_VADEFS = "";
pub const MINGW_SDK_INIT = "";
pub const MINGW_HAS_SECURE_API = @as(c_int, 1);
pub const __STDC_SECURE_LIB__ = @as(c_long, 200411);
pub const __GOT_SECURE_LIB__ = __STDC_SECURE_LIB__;
pub const MINGW_DDK_H = "";
pub const MINGW_HAS_DDK_H = @as(c_int, 1);
pub const _CRT_PACKING = @as(c_int, 8);
pub const __GNUC_VA_LIST = "";
pub const _VA_LIST_DEFINED = "";
pub inline fn _ADDRESSOF(v: anytype) @TypeOf(&v) {
    _ = &v;
    return &v;
}
pub const _crt_va_start = @compileError("unable to translate macro: undefined identifier `__builtin_va_start`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/vadefs.h:48:9
pub const _crt_va_arg = @compileError("unable to translate C expr: unexpected token 'an identifier'");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/vadefs.h:49:9
pub const _crt_va_end = @compileError("unable to translate macro: undefined identifier `__builtin_va_end`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/vadefs.h:50:9
pub const _crt_va_copy = @compileError("unable to translate macro: undefined identifier `__builtin_va_copy`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/vadefs.h:51:9
pub const __CRT_STRINGIZE = @compileError("unable to translate C expr: unexpected token '#'");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw.h:309:9
pub inline fn _CRT_STRINGIZE(_Value: anytype) @TypeOf(__CRT_STRINGIZE(_Value)) {
    _ = &_Value;
    return __CRT_STRINGIZE(_Value);
}
pub const __CRT_WIDE = @compileError("unable to translate macro: undefined identifier `L`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw.h:314:9
pub inline fn _CRT_WIDE(_String: anytype) @TypeOf(__CRT_WIDE(_String)) {
    _ = &_String;
    return __CRT_WIDE(_String);
}
pub const _W64 = "";
pub const _CRTIMP_NOIA64 = _CRTIMP;
pub const _CRTIMP2 = _CRTIMP;
pub const _CRTIMP_ALTERNATIVE = _CRTIMP;
pub const _CRT_ALTERNATIVE_IMPORTED = "";
pub const _MRTIMP2 = _CRTIMP;
pub const _DLL = "";
pub const _MT = "";
pub const _MCRTIMP = _CRTIMP;
pub const _CRTIMP_PURE = _CRTIMP;
pub const _PGLOBAL = "";
pub const _AGLOBAL = "";
pub const _SECURECRT_FILL_BUFFER_PATTERN = @as(c_int, 0xFD);
pub const _CRT_DEPRECATE_TEXT = @compileError("unable to translate macro: undefined identifier `deprecated`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw.h:373:9
pub const _CRT_INSECURE_DEPRECATE_MEMORY = @compileError("unable to translate C expr: unexpected token ''");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw.h:376:9
pub const _CRT_INSECURE_DEPRECATE_GLOBALS = @compileError("unable to translate C expr: unexpected token ''");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw.h:380:9
pub const _CRT_MANAGED_HEAP_DEPRECATE = "";
pub const _CRT_OBSOLETE = @compileError("unable to translate C expr: unexpected token ''");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw.h:388:9
pub const _CONST_RETURN = "";
pub const UNALIGNED = "";
pub const _CRT_ALIGN = @compileError("unable to translate macro: undefined identifier `__aligned__`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw.h:415:9
pub const __CRTDECL = __cdecl;
pub const _ARGMAX = @as(c_int, 100);
pub const _TRUNCATE = @import("std").zig.c_translation.cast(usize, -@as(c_int, 1));
pub inline fn _CRT_UNUSED(x: anytype) anyopaque {
    _ = &x;
    return @import("std").zig.c_translation.cast(anyopaque, x);
}
pub const __USE_MINGW_ANSI_STDIO = @as(c_int, 0);
pub const _CRT_glob = @compileError("unable to translate macro: undefined identifier `_dowildcard`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw.h:479:9
pub const __ANONYMOUS_DEFINED = "";
pub const _ANONYMOUS_UNION = __MINGW_EXTENSION;
pub const _ANONYMOUS_STRUCT = __MINGW_EXTENSION;
pub const _UNION_NAME = @compileError("unable to translate C expr: unexpected token ''");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw.h:499:9
pub const _STRUCT_NAME = @compileError("unable to translate C expr: unexpected token ''");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw.h:500:9
pub const DUMMYUNIONNAME = "";
pub const DUMMYUNIONNAME1 = "";
pub const DUMMYUNIONNAME2 = "";
pub const DUMMYUNIONNAME3 = "";
pub const DUMMYUNIONNAME4 = "";
pub const DUMMYUNIONNAME5 = "";
pub const DUMMYUNIONNAME6 = "";
pub const DUMMYUNIONNAME7 = "";
pub const DUMMYUNIONNAME8 = "";
pub const DUMMYUNIONNAME9 = "";
pub const DUMMYSTRUCTNAME = "";
pub const DUMMYSTRUCTNAME1 = "";
pub const DUMMYSTRUCTNAME2 = "";
pub const DUMMYSTRUCTNAME3 = "";
pub const DUMMYSTRUCTNAME4 = "";
pub const DUMMYSTRUCTNAME5 = "";
pub const __CRT_UUID_DECL = @compileError("unable to translate C expr: unexpected token ''");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw.h:587:9
pub const __MINGW_DEBUGBREAK_IMPL = !(__has_builtin(__debugbreak) != 0);
pub const __MINGW_FASTFAIL_IMPL = !(__has_builtin(__fastfail) != 0);
pub const __MINGW_PREFETCH_IMPL = @compileError("unable to translate macro: undefined identifier `__prefetch`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/_mingw.h:644:9
pub const _CRTNOALIAS = "";
pub const _CRTRESTRICT = "";
pub const _SIZE_T_DEFINED = "";
pub const _SSIZE_T_DEFINED = "";
pub const _RSIZE_T_DEFINED = "";
pub const _INTPTR_T_DEFINED = "";
pub const __intptr_t_defined = "";
pub const _UINTPTR_T_DEFINED = "";
pub const __uintptr_t_defined = "";
pub const _PTRDIFF_T_DEFINED = "";
pub const _PTRDIFF_T_ = "";
pub const _WCHAR_T_DEFINED = "";
pub const _WCTYPE_T_DEFINED = "";
pub const _WINT_T = "";
pub const _ERRCODE_DEFINED = "";
pub const _TIME32_T_DEFINED = "";
pub const _TIME64_T_DEFINED = "";
pub const _TIME_T_DEFINED = "";
pub const _CRT_SECURE_CPP_NOTHROW = @compileError("unable to translate macro: undefined identifier `throw`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/corecrt.h:143:9
pub const __DEFINE_CPP_OVERLOAD_SECURE_FUNC_0_0 = @compileError("unable to translate C expr: unexpected token ''");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/corecrt.h:262:9
pub const __DEFINE_CPP_OVERLOAD_SECURE_FUNC_0_1 = @compileError("unable to translate C expr: unexpected token ''");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/corecrt.h:263:9
pub const __DEFINE_CPP_OVERLOAD_SECURE_FUNC_0_2 = @compileError("unable to translate C expr: unexpected token ''");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/corecrt.h:264:9
pub const __DEFINE_CPP_OVERLOAD_SECURE_FUNC_0_3 = @compileError("unable to translate C expr: unexpected token ''");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/corecrt.h:265:9
pub const __DEFINE_CPP_OVERLOAD_SECURE_FUNC_0_4 = @compileError("unable to translate C expr: unexpected token ''");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/corecrt.h:266:9
pub const __DEFINE_CPP_OVERLOAD_SECURE_FUNC_1_1 = @compileError("unable to translate C expr: unexpected token ''");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/corecrt.h:267:9
pub const __DEFINE_CPP_OVERLOAD_SECURE_FUNC_1_2 = @compileError("unable to translate C expr: unexpected token ''");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/corecrt.h:268:9
pub const __DEFINE_CPP_OVERLOAD_SECURE_FUNC_1_3 = @compileError("unable to translate C expr: unexpected token ''");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/corecrt.h:269:9
pub const __DEFINE_CPP_OVERLOAD_SECURE_FUNC_2_0 = @compileError("unable to translate C expr: unexpected token ''");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/corecrt.h:270:9
pub const __DEFINE_CPP_OVERLOAD_SECURE_FUNC_0_1_ARGLIST = @compileError("unable to translate C expr: unexpected token ''");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/corecrt.h:271:9
pub const __DEFINE_CPP_OVERLOAD_SECURE_FUNC_0_2_ARGLIST = @compileError("unable to translate C expr: unexpected token ''");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/corecrt.h:272:9
pub const __DEFINE_CPP_OVERLOAD_SECURE_FUNC_SPLITPATH = @compileError("unable to translate C expr: unexpected token ''");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/corecrt.h:273:9
pub const __DEFINE_CPP_OVERLOAD_STANDARD_FUNC_0_0 = @compileError("unable to translate macro: undefined identifier `__func_name`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/corecrt.h:277:9
pub const __DEFINE_CPP_OVERLOAD_STANDARD_FUNC_0_1 = @compileError("unable to translate macro: undefined identifier `__func_name`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/corecrt.h:279:9
pub const __DEFINE_CPP_OVERLOAD_STANDARD_FUNC_0_2 = @compileError("unable to translate macro: undefined identifier `__func_name`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/corecrt.h:281:9
pub const __DEFINE_CPP_OVERLOAD_STANDARD_FUNC_0_3 = @compileError("unable to translate macro: undefined identifier `__func_name`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/corecrt.h:283:9
pub const __DEFINE_CPP_OVERLOAD_STANDARD_FUNC_0_4 = @compileError("unable to translate macro: undefined identifier `__func_name`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/corecrt.h:285:9
pub const __DEFINE_CPP_OVERLOAD_STANDARD_FUNC_0_0_EX = @compileError("unable to translate C expr: unexpected token ''");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/corecrt.h:422:9
pub const __DEFINE_CPP_OVERLOAD_STANDARD_FUNC_0_1_EX = @compileError("unable to translate C expr: unexpected token ''");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/corecrt.h:423:9
pub const __DEFINE_CPP_OVERLOAD_STANDARD_FUNC_0_2_EX = @compileError("unable to translate C expr: unexpected token ''");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/corecrt.h:424:9
pub const __DEFINE_CPP_OVERLOAD_STANDARD_FUNC_0_3_EX = @compileError("unable to translate C expr: unexpected token ''");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/corecrt.h:425:9
pub const __DEFINE_CPP_OVERLOAD_STANDARD_FUNC_0_4_EX = @compileError("unable to translate C expr: unexpected token ''");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/corecrt.h:426:9
pub const _TAGLC_ID_DEFINED = "";
pub const _THREADLOCALEINFO = "";
pub const __crt_typefix = @compileError("unable to translate C expr: unexpected token ''");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/corecrt.h:486:9
pub const _CRT_USE_WINAPI_FAMILY_DESKTOP_APP = "";
pub const _CRT_INTERNAL_PRINTF_LEGACY_VSPRINTF_NULL_TERMINATION = @as(c_ulonglong, 0x0001);
pub const _CRT_INTERNAL_PRINTF_STANDARD_SNPRINTF_BEHAVIOR = @as(c_ulonglong, 0x0002);
pub const _CRT_INTERNAL_PRINTF_LEGACY_WIDE_SPECIFIERS = @as(c_ulonglong, 0x0004);
pub const _CRT_INTERNAL_PRINTF_LEGACY_MSVCRT_COMPATIBILITY = @as(c_ulonglong, 0x0008);
pub const _CRT_INTERNAL_PRINTF_LEGACY_THREE_DIGIT_EXPONENTS = @as(c_ulonglong, 0x0010);
pub const _CRT_INTERNAL_PRINTF_STANDARD_ROUNDING = @as(c_ulonglong, 0x0020);
pub const _CRT_INTERNAL_SCANF_SECURECRT = @as(c_ulonglong, 0x0001);
pub const _CRT_INTERNAL_SCANF_LEGACY_WIDE_SPECIFIERS = @as(c_ulonglong, 0x0002);
pub const _CRT_INTERNAL_SCANF_LEGACY_MSVCRT_COMPATIBILITY = @as(c_ulonglong, 0x0004);
pub const _CRT_INTERNAL_LOCAL_PRINTF_OPTIONS = __local_stdio_printf_options().*;
pub const _CRT_INTERNAL_LOCAL_SCANF_OPTIONS = __local_stdio_scanf_options().*;
pub const BUFSIZ = @as(c_int, 512);
pub const _NFILE = _NSTREAM_;
pub const _NSTREAM_ = @as(c_int, 512);
pub const _IOB_ENTRIES = @as(c_int, 20);
pub const EOF = -@as(c_int, 1);
pub const _FILE_DEFINED = "";
pub const _P_tmpdir = "\\";
pub const _wP_tmpdir = "\\";
pub const L_tmpnam = @as(c_int, 260);
pub const SEEK_CUR = @as(c_int, 1);
pub const SEEK_END = @as(c_int, 2);
pub const SEEK_SET = @as(c_int, 0);
pub const STDIN_FILENO = @as(c_int, 0);
pub const STDOUT_FILENO = @as(c_int, 1);
pub const STDERR_FILENO = @as(c_int, 2);
pub const FILENAME_MAX = @as(c_int, 260);
pub const FOPEN_MAX = @as(c_int, 20);
pub const _SYS_OPEN = @as(c_int, 20);
pub const TMP_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const NULL = @import("std").zig.c_translation.cast(?*anyopaque, @as(c_int, 0));
pub const _OFF_T_DEFINED = "";
pub const _OFF_T_ = "";
pub const _OFF64_T_DEFINED = "";
pub const _FILE_OFFSET_BITS_SET_OFFT = "";
pub const _iob = __iob_func();
pub const _FPOS_T_DEFINED = "";
pub inline fn _FPOSOFF(fp: anytype) c_long {
    _ = &fp;
    return @import("std").zig.c_translation.cast(c_long, fp);
}
pub const _STDSTREAM_DEFINED = "";
pub const stdin = __acrt_iob_func(@as(c_int, 0));
pub const stdout = __acrt_iob_func(@as(c_int, 1));
pub const stderr = __acrt_iob_func(@as(c_int, 2));
pub const _IOFBF = @as(c_int, 0x0000);
pub const _IOLBF = @as(c_int, 0x0040);
pub const _IONBF = @as(c_int, 0x0004);
pub const __MINGW_PRINTF_FORMAT = @compileError("unable to translate macro: undefined identifier `__printf__`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/stdio.h:277:9
pub const __MINGW_SCANF_FORMAT = @compileError("unable to translate macro: undefined identifier `__scanf__`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/stdio.h:278:9
pub const _FILE_OFFSET_BITS_SET_FSEEKO = "";
pub const _FILE_OFFSET_BITS_SET_FTELLO = "";
pub const _CRT_PERROR_DEFINED = "";
pub const popen = _popen;
pub const pclose = _pclose;
pub const _CRT_DIRECTORY_DEFINED = "";
pub const _WSTDIO_DEFINED = "";
pub const WEOF = @import("std").zig.c_translation.cast(wint_t, @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xFFFF, .hex));
pub const _INC_SWPRINTF_INL = "";
pub const _CRT_WPERROR_DEFINED = "";
pub const wpopen = _wpopen;
pub inline fn _putwc_nolock(_c: anytype, _stm: anytype) @TypeOf(_fputwc_nolock(_c, _stm)) {
    _ = &_c;
    _ = &_stm;
    return _fputwc_nolock(_c, _stm);
}
pub inline fn _getwc_nolock(_c: anytype) @TypeOf(_fgetwc_nolock(_c)) {
    _ = &_c;
    return _fgetwc_nolock(_c);
}
pub const _STDIO_DEFINED = "";
pub inline fn _getchar_nolock() @TypeOf(_getc_nolock(stdin)) {
    return _getc_nolock(stdin);
}
pub inline fn _putchar_nolock(_c: anytype) @TypeOf(_putc_nolock(_c, stdout)) {
    _ = &_c;
    return _putc_nolock(_c, stdout);
}
pub inline fn _getwchar_nolock() @TypeOf(_getwc_nolock(stdin)) {
    return _getwc_nolock(stdin);
}
pub inline fn _putwchar_nolock(_c: anytype) @TypeOf(_putwc_nolock(_c, stdout)) {
    _ = &_c;
    return _putwc_nolock(_c, stdout);
}
pub const P_tmpdir = _P_tmpdir;
pub const SYS_OPEN = _SYS_OPEN;
pub const __MINGW_MBWC_CONVERT_DEFINED = "";
pub const _WSPAWN_DEFINED = "";
pub const _P_WAIT = @as(c_int, 0);
pub const _P_NOWAIT = @as(c_int, 1);
pub const _OLD_P_OVERLAY = @as(c_int, 2);
pub const _P_NOWAITO = @as(c_int, 3);
pub const _P_DETACH = @as(c_int, 4);
pub const _P_OVERLAY = @as(c_int, 2);
pub const _WAIT_CHILD = @as(c_int, 0);
pub const _WAIT_GRANDCHILD = @as(c_int, 1);
pub const _SPAWNV_DEFINED = "";
pub const _INC_STDIO_S = "";
pub const _SECIMP = @compileError("unable to translate macro: undefined identifier `dllimport`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/sec_api/stdio_s.h:16:9
pub const _STDIO_S_DEFINED = "";
pub const L_tmpnam_s = L_tmpnam;
pub const TMP_MAX_S = TMP_MAX;
pub const _WSTDIO_S_DEFINED = "";
pub const __CLANG_LIMITS_H = "";
pub const _GCC_LIMITS_H_ = "";
pub const _INC_CRTDEFS = "";
pub const _INC_LIMITS = "";
pub const PATH_MAX = @as(c_int, 260);
pub const CHAR_BIT = @as(c_int, 8);
pub const SCHAR_MIN = -@as(c_int, 128);
pub const SCHAR_MAX = @as(c_int, 127);
pub const UCHAR_MAX = @as(c_int, 0xff);
pub const CHAR_MIN = SCHAR_MIN;
pub const CHAR_MAX = SCHAR_MAX;
pub const MB_LEN_MAX = @as(c_int, 5);
pub const SHRT_MIN = -@import("std").zig.c_translation.promoteIntLiteral(c_int, 32768, .decimal);
pub const SHRT_MAX = @as(c_int, 32767);
pub const USHRT_MAX = @as(c_uint, 0xffff);
pub const INT_MIN = -@import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal) - @as(c_int, 1);
pub const INT_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const UINT_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 0xffffffff, .hex);
pub const LONG_MIN = -@as(c_long, 2147483647) - @as(c_int, 1);
pub const LONG_MAX = @as(c_long, 2147483647);
pub const ULONG_MAX = @as(c_ulong, 0xffffffff);
pub const LLONG_MAX = @as(c_longlong, 9223372036854775807);
pub const LLONG_MIN = -@as(c_longlong, 9223372036854775807) - @as(c_int, 1);
pub const ULLONG_MAX = @as(c_ulonglong, 0xffffffffffffffff);
pub const _I8_MIN = -@as(c_int, 127) - @as(c_int, 1);
pub const _I8_MAX = @as(c_int, 127);
pub const _UI8_MAX = @as(c_uint, 0xff);
pub const _I16_MIN = -@as(c_int, 32767) - @as(c_int, 1);
pub const _I16_MAX = @as(c_int, 32767);
pub const _UI16_MAX = @as(c_uint, 0xffff);
pub const _I32_MIN = -@import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal) - @as(c_int, 1);
pub const _I32_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const _UI32_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 0xffffffff, .hex);
pub const LONG_LONG_MAX = @as(c_longlong, 9223372036854775807);
pub const LONG_LONG_MIN = -LONG_LONG_MAX - @as(c_int, 1);
pub const ULONG_LONG_MAX = (@as(c_ulonglong, 2) * LONG_LONG_MAX) + @as(c_ulonglong, 1);
pub const _I64_MIN = -@as(c_longlong, 9223372036854775807) - @as(c_int, 1);
pub const _I64_MAX = @as(c_longlong, 9223372036854775807);
pub const _UI64_MAX = @as(c_ulonglong, 0xffffffffffffffff);
pub const SIZE_MAX = _UI64_MAX;
pub const SSIZE_MAX = _I64_MAX;
pub const __XML_STRING_H__ = "";
pub const __need___va_list = "";
pub const __need_va_list = "";
pub const __need_va_arg = "";
pub const __need___va_copy = "";
pub const __need_va_copy = "";
pub const __STDARG_H = "";
pub const _VA_LIST = "";
pub const va_start = @compileError("unable to translate macro: undefined identifier `__builtin_va_start`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\include/__stdarg_va_arg.h:17:9
pub const va_end = @compileError("unable to translate macro: undefined identifier `__builtin_va_end`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\include/__stdarg_va_arg.h:19:9
pub const va_arg = @compileError("unable to translate C expr: unexpected token 'an identifier'");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\include/__stdarg_va_arg.h:20:9
pub const __va_copy = @compileError("unable to translate macro: undefined identifier `__builtin_va_copy`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\include/__stdarg___va_copy.h:11:9
pub const va_copy = @compileError("unable to translate macro: undefined identifier `__builtin_va_copy`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\include/__stdarg_va_copy.h:11:9
pub const BAD_CAST = @compileError("unable to translate C expr: unexpected token ''");
// .zig-cache\o\d7601404d236499ce55c245150822482/libxml/xmlstring.h:35:9
pub const BASE_BUFFER_SIZE = @as(c_int, 4096);
pub const LIBXML2_NEW_BUFFER = "";
pub const XML_XML_NAMESPACE = @compileError("unable to translate C expr: unexpected token 'const'");
// .zig-cache\o\d7601404d236499ce55c245150822482/libxml/tree.h:140:9
pub const XML_XML_ID = @compileError("unable to translate C expr: unexpected token 'const'");
// .zig-cache\o\d7601404d236499ce55c245150822482/libxml/tree.h:148:9
pub const XML_DOCB_DOCUMENT_NODE = @as(c_int, 21);
pub const __XML_REGEXP_H__ = "";
pub const XML_LOCAL_NAMESPACE = XML_NAMESPACE_DECL;
pub inline fn XML_GET_CONTENT(n: anytype) @TypeOf(if (n.*.type == XML_ELEMENT_NODE) NULL else n.*.content) {
    _ = &n;
    return if (n.*.type == XML_ELEMENT_NODE) NULL else n.*.content;
}
pub inline fn XML_GET_LINE(n: anytype) @TypeOf(xmlGetLineNo(n)) {
    _ = &n;
    return xmlGetLineNo(n);
}
pub const xmlChildrenNode = @compileError("unable to translate macro: undefined identifier `children`");
// .zig-cache\o\d7601404d236499ce55c245150822482/libxml/tree.h:640:9
pub const xmlRootNode = @compileError("unable to translate macro: undefined identifier `children`");
// .zig-cache\o\d7601404d236499ce55c245150822482/libxml/tree.h:650:9
pub const __DEBUG_MEMORY_ALLOC__ = "";
pub const __XML_THREADS_H__ = "";
pub const __XML_GLOBALS_H = "";
pub const __XML_PARSER_H__ = "";
pub const __XML_DICT_H__ = "";
pub const __need_ptrdiff_t = "";
pub const __need_size_t = "";
pub const __need_wchar_t = "";
pub const __need_NULL = "";
pub const __need_max_align_t = "";
pub const __need_offsetof = "";
pub const __STDDEF_H = "";
pub const _PTRDIFF_T = "";
pub const _SIZE_T = "";
pub const _WCHAR_T = "";
pub const __CLANG_MAX_ALIGN_T_DEFINED = "";
pub const offsetof = @compileError("unable to translate C expr: unexpected token 'an identifier'");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\include/__stddef_offsetof.h:16:9
pub const __XML_HASH_H__ = "";
pub inline fn XML_CAST_FPTR(fptr: anytype) @TypeOf(fptr) {
    _ = &fptr;
    return fptr;
}
pub const __XML_VALID_H__ = "";
pub const __XML_ERROR_H__ = "";
pub const __XML_LINK_INCLUDE__ = "";
pub const __XML_AUTOMATA_H__ = "";
pub const __XML_ENTITIES_H__ = "";
pub const XML_DEFAULT_VERSION = "1.0";
pub const XML_DETECT_IDS = @as(c_int, 2);
pub const XML_COMPLETE_ATTRS = @as(c_int, 4);
pub const XML_SKIP_IDS = @as(c_int, 8);
pub const XML_SAX2_MAGIC = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xDEEDBEAF, .hex);
pub const __XML_CHAR_ENCODING_H__ = "";
pub const __XML_IO_H__ = "";
pub const __XML_SAX2_H__ = "";
pub const _INC_STDLIB = "";
pub const _INC_CORECRT_WSTDLIB = "";
pub const EXIT_SUCCESS = @as(c_int, 0);
pub const EXIT_FAILURE = @as(c_int, 1);
pub const _ONEXIT_T_DEFINED = "";
pub const onexit_t = _onexit_t;
pub const _DIV_T_DEFINED = "";
pub const _CRT_DOUBLE_DEC = "";
pub inline fn _PTR_LD(x: anytype) [*c]u8 {
    _ = &x;
    return @import("std").zig.c_translation.cast([*c]u8, &x.*.ld);
}
pub const RAND_MAX = @as(c_int, 0x7fff);
pub const MB_CUR_MAX = ___mb_cur_max_func();
pub const __mb_cur_max = ___mb_cur_max_func();
pub inline fn __max(a: anytype, b: anytype) @TypeOf(if (a > b) a else b) {
    _ = &a;
    _ = &b;
    return if (a > b) a else b;
}
pub inline fn __min(a: anytype, b: anytype) @TypeOf(if (a < b) a else b) {
    _ = &a;
    _ = &b;
    return if (a < b) a else b;
}
pub const _MAX_PATH = @as(c_int, 260);
pub const _MAX_DRIVE = @as(c_int, 3);
pub const _MAX_DIR = @as(c_int, 256);
pub const _MAX_FNAME = @as(c_int, 256);
pub const _MAX_EXT = @as(c_int, 256);
pub const _OUT_TO_DEFAULT = @as(c_int, 0);
pub const _OUT_TO_STDERR = @as(c_int, 1);
pub const _OUT_TO_MSGBOX = @as(c_int, 2);
pub const _REPORT_ERRMODE = @as(c_int, 3);
pub const _WRITE_ABORT_MSG = @as(c_int, 0x1);
pub const _CALL_REPORTFAULT = @as(c_int, 0x2);
pub const _MAX_ENV = @as(c_int, 32767);
pub const _CRT_ERRNO_DEFINED = "";
pub const errno = _errno().*;
pub const _doserrno = __doserrno().*;
pub const _sys_nerr = __sys_nerr().*;
pub const _sys_errlist = __sys_errlist();
pub const _fmode = __p__fmode().*;
pub const __argc = __p___argc().*;
pub const __argv = __p___argv().*;
pub const __wargv = __p___wargv().*;
pub const _pgmptr = __p__pgmptr().*;
pub const _wpgmptr = __p__wpgmptr().*;
pub const _environ = __p__environ().*;
pub const _wenviron = __p__wenviron().*;
pub const _osplatform = __p__osplatform().*;
pub const _osver = __p__osver().*;
pub const _winver = __p__winver().*;
pub const _winmajor = __p__winmajor().*;
pub const _winminor = __p__winminor().*;
pub const _countof = @compileError("unable to translate C expr: expected ')' instead got '['");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/stdlib.h:263:9
pub const _CRT_TERMINATE_DEFINED = "";
pub const _CRT_ABS_DEFINED = "";
pub const _CRT_ATOF_DEFINED = "";
pub const _CRT_ALGO_DEFINED = "";
pub const _CRT_SYSTEM_DEFINED = "";
pub const _CRT_ALLOCATION_DEFINED = "";
pub const _WSTDLIB_DEFINED = "";
pub const _CRT_WSYSTEM_DEFINED = "";
pub const _CVTBUFSIZE = @as(c_int, 309) + @as(c_int, 40);
pub const _WSTDLIBP_DEFINED = "";
pub const sys_errlist = _sys_errlist;
pub const sys_nerr = _sys_nerr;
pub const environ = _environ;
pub const _CRT_SWAB_DEFINED = "";
pub const _INC_STDLIB_S = "";
pub const _QSORT_S_DEFINED = "";
pub const _MALLOC_H_ = "";
pub const _HEAP_MAXREQ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xFFFFFFFFFFFFFFE0, .hex);
pub const _STATIC_ASSERT = @compileError("unable to translate C expr: unexpected token '_Static_assert'");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/malloc.h:29:9
pub const _HEAPEMPTY = -@as(c_int, 1);
pub const _HEAPOK = -@as(c_int, 2);
pub const _HEAPBADBEGIN = -@as(c_int, 3);
pub const _HEAPBADNODE = -@as(c_int, 4);
pub const _HEAPEND = -@as(c_int, 5);
pub const _HEAPBADPTR = -@as(c_int, 6);
pub const _FREEENTRY = @as(c_int, 0);
pub const _USEDENTRY = @as(c_int, 1);
pub const _HEAPINFO_DEFINED = "";
pub const _amblksiz = __p__amblksiz().*;
pub const __MM_MALLOC_H = "";
pub const _MAX_WAIT_MALLOC_CRT = @import("std").zig.c_translation.promoteIntLiteral(c_int, 60000, .decimal);
pub const _alloca = @compileError("unable to translate macro: undefined identifier `__builtin_alloca`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/malloc.h:163:9
pub const _ALLOCA_S_THRESHOLD = @as(c_int, 1024);
pub const _ALLOCA_S_STACK_MARKER = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xCCCC, .hex);
pub const _ALLOCA_S_HEAP_MARKER = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xDDDD, .hex);
pub const _ALLOCA_S_MARKER_SIZE = @as(c_int, 16);
pub inline fn _malloca(size: anytype) @TypeOf(if ((size + _ALLOCA_S_MARKER_SIZE) <= _ALLOCA_S_THRESHOLD) _MarkAllocaS(_alloca(size + _ALLOCA_S_MARKER_SIZE), _ALLOCA_S_STACK_MARKER) else _MarkAllocaS(malloc(size + _ALLOCA_S_MARKER_SIZE), _ALLOCA_S_HEAP_MARKER)) {
    _ = &size;
    return if ((size + _ALLOCA_S_MARKER_SIZE) <= _ALLOCA_S_THRESHOLD) _MarkAllocaS(_alloca(size + _ALLOCA_S_MARKER_SIZE), _ALLOCA_S_STACK_MARKER) else _MarkAllocaS(malloc(size + _ALLOCA_S_MARKER_SIZE), _ALLOCA_S_HEAP_MARKER);
}
pub const _FREEA_INLINE = "";
pub const alloca = @compileError("unable to translate macro: undefined identifier `__builtin_alloca`");
// C:\Users\Katie\Documents\zig-x86_64-windows-0.15.1\lib\libc\include\any-windows-any/malloc.h:238:9
pub const __XML_RELAX_NG__ = "";
pub const __XML_SCHEMA_H__ = "";
pub const threadlocaleinfostruct = struct_threadlocaleinfostruct;
pub const threadmbcinfostruct = struct_threadmbcinfostruct;
pub const __lc_time_data = struct___lc_time_data;
pub const localeinfo_struct = struct_localeinfo_struct;
pub const tagLC_ID = struct_tagLC_ID;
pub const _iobuf = struct__iobuf;
pub const _xmlCharEncodingHandler = struct__xmlCharEncodingHandler;
pub const _xmlBuf = struct__xmlBuf;
pub const _xmlParserInputBuffer = struct__xmlParserInputBuffer;
pub const _xmlOutputBuffer = struct__xmlOutputBuffer;
pub const _xmlDtd = struct__xmlDtd;
pub const _xmlNs = struct__xmlNs;
pub const _xmlDoc = struct__xmlDoc;
pub const _xmlAttr = struct__xmlAttr;
pub const _xmlNode = struct__xmlNode;
pub const _xmlEntity = struct__xmlEntity;
pub const _xmlParserInput = struct__xmlParserInput;
pub const _xmlEnumeration = struct__xmlEnumeration;
pub const _xmlElementContent = struct__xmlElementContent;
pub const _xmlSAXLocator = struct__xmlSAXLocator;
pub const _xmlError = struct__xmlError;
pub const _xmlSAXHandler = struct__xmlSAXHandler;
pub const _xmlParserNodeInfo = struct__xmlParserNodeInfo;
pub const _xmlParserNodeInfoSeq = struct__xmlParserNodeInfoSeq;
pub const _xmlValidState = struct__xmlValidState;
pub const _xmlValidCtxt = struct__xmlValidCtxt;
pub const _xmlStartTag = struct__xmlStartTag;
pub const _xmlHashTable = struct__xmlHashTable;
pub const _xmlParserCtxt = struct__xmlParserCtxt;
pub const _xmlBuffer = struct__xmlBuffer;
pub const _xmlNotation = struct__xmlNotation;
pub const _xmlAttribute = struct__xmlAttribute;
pub const _xmlElement = struct__xmlElement;
pub const _xmlID = struct__xmlID;
pub const _xmlRef = struct__xmlRef;
pub const _xmlDOMWrapCtxt = struct__xmlDOMWrapCtxt;
pub const _xmlMutex = struct__xmlMutex;
pub const _xmlRMutex = struct__xmlRMutex;
pub const _xmlLink = struct__xmlLink;
pub const _xmlList = struct__xmlList;
pub const _xmlSAXHandlerV1 = struct__xmlSAXHandlerV1;
pub const _div_t = struct__div_t;
pub const _ldiv_t = struct__ldiv_t;
pub const _heapinfo = struct__heapinfo;
pub const _xmlGlobalState = struct__xmlGlobalState;
pub const _xmlRelaxNG = struct__xmlRelaxNG;
pub const _xmlRelaxNGParserCtxt = struct__xmlRelaxNGParserCtxt;
pub const _xmlRelaxNGValidCtxt = struct__xmlRelaxNGValidCtxt;
pub const _xmlSchema = struct__xmlSchema;
pub const _xmlSchemaParserCtxt = struct__xmlSchemaParserCtxt;
pub const _xmlSchemaValidCtxt = struct__xmlSchemaValidCtxt;
pub const _xmlSchemaSAXPlug = struct__xmlSchemaSAXPlug;
pub const _xmlTextReader = struct__xmlTextReader;
