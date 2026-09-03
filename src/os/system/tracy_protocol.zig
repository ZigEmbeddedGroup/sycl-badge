/// This file contains the data layouts of the terry protocol for 0.14.0
const std = @import("std");
const builtin = @import("builtin");

inline fn static_assert(condition: bool, err: []const u8) void {
    if (!condition) @compileError(err);
}

comptime {
    if (builtin.cpu.arch.endian() != .little)
        @compileError("Tracy only supports little endian CPUs");
}

/// ------------------------- Messages for Application comms with server ----------------------------------
pub const Type = enum(u8) {
    ZoneText,
    ZoneName,
    Message,
    MessageColor,
    MessageCallstack,
    MessageColorCallstack,
    MessageAppInfo,
    ZoneBeginAllocSrcLoc,
    ZoneBeginAllocSrcLocCallstack,
    CallstackSerial,
    Callstack,
    CallstackAlloc,
    CallstackSample,
    CallstackSample32,
    CallstackSample16,
    CallstackSampleContextSwitch,
    CallstackSampleContextSwitch32,
    CallstackSampleContextSwitch16,
    FrameImage,
    ZoneBegin,
    ZoneBegin32,
    ZoneBegin16,
    ZoneBeginCallstack,
    ZoneBeginCallstack32,
    ZoneBeginCallstack16,
    ZoneEnd,
    ZoneEnd32,
    ZoneEnd16,
    LockWait,
    LockObtain,
    LockRelease,
    LockSharedWait,
    LockSharedObtain,
    LockSharedRelease,
    LockName,
    MemAlloc,
    MemAllocNamed,
    MemFree,
    MemFreeNamed,
    MemAllocCallstack,
    MemAllocCallstackNamed,
    MemFreeCallstack,
    MemFreeCallstackNamed,
    MemDiscard,
    MemDiscardCallstack,
    GpuZoneBegin,
    GpuZoneBeginCallstack,
    GpuZoneBeginAllocSrcLoc,
    GpuZoneBeginAllocSrcLocCallstack,
    GpuZoneEnd,
    GpuZoneBeginSerial,
    GpuZoneBeginCallstackSerial,
    GpuZoneBeginAllocSrcLocSerial,
    GpuZoneBeginAllocSrcLocCallstackSerial,
    GpuZoneEndSerial,
    PlotDataInt,
    PlotDataFloat,
    PlotDataDouble,
    ContextSwitch,
    ThreadWakeup,
    GpuTime,
    GpuContextName,
    GpuAnnotationName,
    CallstackFrameSize,
    SymbolInformation,
    ExternalNameMetadata,
    SymbolCodeMetadata,
    SourceCodeMetadata,
    FiberEnter,
    FiberLeave,
    SectionEnter,
    SectionLeave,
    SectionSetup,
    Terminate,
    KeepAlive,
    ThreadContext,
    GpuCalibration,
    GpuTimeSync,
    Crash,
    CrashReport,
    ZoneValidation,
    ZoneColor,
    ZoneValue,
    FrameMarkMsg,
    FrameMarkMsgStart,
    FrameMarkMsgEnd,
    FrameVsync,
    SourceLocation,
    LockAnnounce,
    LockTerminate,
    LockMark,
    MessageLiteral,
    MessageLiteralColor,
    MessageLiteralCallstack,
    MessageLiteralColorCallstack,
    GpuNewContext,
    CallstackFrame,
    SysTimeReport,
    SysPowerReport,
    TidToPid,
    HwSampleCpuCycle,
    HwSampleInstructionRetired,
    HwSampleCacheReference,
    HwSampleCacheMiss,
    HwSampleBranchRetired,
    HwSampleBranchMiss,
    PlotConfig,
    ParamSetup,
    AckServerQueryNoop,
    AckSourceCodeNotAvailable,
    AckSymbolCodeNotAvailable,
    CpuTopology,
    SingleStringData,
    SecondStringData,
    SingleStringData8,
    SecondStringData8,
    MemNamePayload,
    ThreadGroupHint,
    GpuZoneAnnotation,
    StringData,
    ThreadName,
    PlotName,
    SourceLocationPayload,
    CallstackPayload,
    CallstackAllocPayload,
    FrameName,
    FrameImageData,
    ExternalName,
    ExternalThreadName,
    SymbolCode,
    SourceCode,
    FiberName,
    _,

    pub const NUM_TYPES = @typeInfo(@This()).@"enum".field_names.len;
};

fn Extend(A: type, B: type) type {
    const field_names = @typeInfo(A).@"struct".field_names ++ @typeInfo(B).@"struct".field_names;
    const field_types = @typeInfo(A).@"struct".field_types ++ @typeInfo(B).@"struct".field_types;
    const field_attrs = @typeInfo(A).@"struct".field_attrs ++ @typeInfo(B).@"struct".field_attrs;
    return @Struct(.@"extern", null, field_names, field_types, field_attrs);
}

pub const Empty = extern struct {};

pub const ThreadContext = extern struct {
    thread: u32 align(1),
};

pub const ZoneBeginLean = extern struct {
    time: i64 align(1),
};

pub const ZoneBegin = Extend(ZoneBeginLean, extern struct {
    srcloc: u64 align(1), // ptr
});

pub const ZoneBeginThread = Extend(ZoneBegin, extern struct {
    thread: u32 align(1),
});

pub const ZoneBegin32 = extern struct {
    time: u32 align(1),
    srcloc: u64 align(1),
};

pub const ZoneBegin16 = extern struct {
    time: u16 align(1),
    srcloc: u64 align(1),
};

pub const ZoneEnd = extern struct {
    time: i64 align(1),
};

pub const ZoneEnd32 = extern struct {
    time: u32 align(1),
};

pub const ZoneEnd16 = extern struct {
    time: u16 align(1),
};

pub const ZoneEndThread = Extend(ZoneEnd, extern struct {
    thread: u32 align(1),
});

pub const ZoneValidation = extern struct {
    id: u32 align(1),
};

pub const ZoneValidationThread = Extend(ZoneValidation, extern struct {
    thread: u32 align(1),
});

pub const ZoneColor = extern struct {
    b: u8 align(1),
    g: u8 align(1),
    r: u8 align(1),
};

pub const ZoneColorThread = Extend(ZoneColor, extern struct {
    thread: u32 align(1),
});

pub const ZoneValue = extern struct {
    value: u64 align(1),
};

pub const ZoneValueThread = Extend(ZoneValue, extern struct {
    thread: u32 align(1),
});

pub const StringTransfer = extern struct {
    ptr: u64 align(1),
};

pub const StringTransfer16 = Extend(StringTransfer, extern struct {
    len: u16 align(1),
});

pub const FrameMark = extern struct {
    time: i64 align(1),
    name: u64 align(1), // ptr
};

pub const FrameVsync = extern struct {
    time: i64 align(1),
    id: u32 align(1),
};

pub const FrameImage = extern struct {
    frame: u32 align(1),
    w: u16 align(1),
    h: u16 align(1),
    flip: u8 align(1),
};

pub const FrameImageFat = Extend(FrameImage, extern struct {
    image: u64 align(1), // ptr
});

pub const SourceLocation = extern struct {
    name: u64 align(1),
    function: u64 align(1), // ptr
    file: u64 align(1), // ptr
    line: u32 align(1),
    b: u8 align(1),
    g: u8 align(1),
    r: u8 align(1),
};

pub const ZoneTextFat = extern struct {
    text: u64 align(1), // ptr
    size: u16 align(1),
};

pub const ZoneTextFatThread = Extend(ZoneTextFat, extern struct {
    thread: u32 align(1),
});

pub const LockType = enum(u8) {
    Lockable,
    SharedLockable,
    _,
};

pub const LockAnnounce = extern struct {
    id: u32 align(1),
    time: i64 align(1),
    lckloc: u64 align(1), // ptr
    type: LockType align(1),
};

pub const FiberEnter = extern struct {
    time: i64 align(1),
    fiber: u64 align(1), // ptr
    thread: u32 align(1),
    groupHint: i32 align(1),
};

pub const FiberLeave = extern struct {
    time: i64 align(1),
    thread: u32 align(1),
};

pub const SectionEnter = extern struct {
    time: i64 align(1),
    id: u32 align(1),
    category: u16 align(1),
};

pub const SectionEnterFat = Extend(SectionEnter, extern struct {
    text: u64 align(1), // ptr
    size: u16 align(1),
});

pub const SectionLeave = extern struct {
    time: i64 align(1),
    id: u32 align(1),
};

pub const SectionSetup = extern struct {
    category: u16 align(1),
};

pub const SectionSetupFat = Extend(SectionSetup, extern struct {
    text: u64 align(1), // ptr
    size: u16 align(1),
});

pub const LockTerminate = extern struct {
    id: u32 align(1),
    time: i64 align(1),
};

pub const LockWait = extern struct {
    thread: u32 align(1),
    id: u32 align(1),
    time: i64 align(1),
};

pub const LockObtain = extern struct {
    thread: u32 align(1),
    id: u32 align(1),
    time: i64 align(1),
};

pub const LockRelease = extern struct {
    id: u32 align(1),
    time: i64 align(1),
};

pub const LockReleaseShared = Extend(LockRelease, extern struct {
    thread: u32 align(1),
});

pub const LockMark = extern struct {
    thread: u32 align(1),
    id: u32 align(1),
    srcloc: u64 align(1), // ptr
};

pub const LockName = extern struct {
    id: u32 align(1),
};

pub const LockNameFat = Extend(LockName, extern struct {
    name: u64 align(1), // ptr
    size: u16 align(1),
});

pub const PlotDataBase = extern struct {
    name: u64 align(1), // ptr
    time: i64 align(1),
};

pub const PlotDataInt = Extend(PlotDataBase, extern struct {
    val: i64 align(1),
});

pub const PlotDataFloat = Extend(PlotDataBase, extern struct {
    val: f32 align(1),
});

pub const PlotDataDouble = Extend(PlotDataBase, extern struct {
    val: f64 align(1),
});

pub const MessageSourceType = enum(u8) {
    User,
    Tracy,
    _,

    pub const COUNT = @typeInfo(@This()).@"enum".fields.len;
};

pub const MessageSeverity = enum(u8) {
    Trace, // Broadly track variable states and events in the software program.
    Debug, // Describes variable states and details about specific internal events in the software, that are useful for investigations.
    Info, // Describes normal events, which inform on the expected progress and state of your software.
    Warning, // Describes potentially dangerous situations caused by unexpected events and states.
    Error, // Describes the occurrence of unexpected behavior. Does not interrupt the execution of the software.
    Fatal, // Describes a critical event that will lead to a software failure/crash.
    _,

    pub const COUNT = @typeInfo(@This()).@"enum".fields.len;
};

pub fn MakeMessageMetadata(source: MessageSourceType, severity: MessageSeverity) u8 {
    static_assert(MessageSourceType.COUNT < (1 << 4), "We use 4 bits for the messages source.");
    static_assert(MessageSeverity.COUNT < (1 << 4), "We use 4 bits for the messages severity.");
    return (@backingInt(severity) << 4) | @backingInt(source);
}

pub fn MessageSourceFromMetadata(metadata: u8) MessageSourceType {
    return @fromBackingInt(@intCast(metadata & 0x0F));
}

pub fn MessageSeverityFromMetadata(metadata: u8) MessageSeverity {
    return @fromBackingInt(@intCast((metadata & 0xF0) >> 4));
}

// QueueMessage*Metadata and QueMessageLiteral* are the only structures sent over the wire
// All other variants are used only internally to dispatch from the thread to the profiler and interpreted by Profiler::Dequeue
pub const Message = extern struct {
    time: i64 align(1),
};

pub const MessageColor = Extend(Message, extern struct {
    b: u8 align(1),
    g: u8 align(1),
    r: u8 align(1),
});

pub const MessageMetadata = Extend(Message, extern struct {
    metadata: u8 align(1),
});

pub const MessageColorMetadata = Extend(MessageColor, extern struct {
    metadata: u8 align(1),
});

pub const MessageLiteral = Extend(Message, extern struct {
    textAndMetadata: TaggedUserlandAddress align(1), // ptr + log level/channels
});

pub const MessageLiteralThread = Extend(MessageLiteral, extern struct {
    thread: u32 align(1),
});

pub const MessageColorLiteral = Extend(MessageColor, extern struct {
    textAndMetadata: TaggedUserlandAddress align(1), // ptr + log level/channels
});

pub const MessageColorLiteralThread = Extend(MessageColorLiteral, extern struct {
    thread: u32 align(1),
});

pub const MessageFat = Extend(Message, extern struct {
    textAndMetadata: TaggedUserlandAddress align(1), // ptr + log level/channels
    size: u16 align(1),
});

pub const MessageFatThread = Extend(MessageFat, extern struct {
    thread: u32 align(1),
});

pub const MessageColorFat = Extend(MessageColor, extern struct {
    textAndMetadata: TaggedUserlandAddress align(1), // ptr + log level/channels
    size: u16 align(1),
});

pub const MessageColorFatThread = Extend(MessageColorFat, extern struct {
    thread: u32 align(1),
});

// Don't change order, only add new entries at the end, this is also used on trace dumps!
pub const GpuContextType = enum(u8) {
    Invalid,
    OpenGl,
    Vulkan,
    OpenCL,
    Direct3D12,
    Direct3D11,
    Metal,
    Custom,
    CUDA,
    Rocprof,
    WebGPU,
    _,
};

pub const GpuContextFlags = packed struct(u8) {
    GpuContextCalibration: bool,
    _reserved: u7 = 0,
};

pub const GpuNewContext = extern struct {
    cpuTime: i64 align(1),
    gpuTime: i64 align(1),
    thread: u32 align(1),
    period: f32 align(1),
    context: u8 align(1),
    flags: GpuContextFlags align(1),
    type: GpuContextType align(1),
};

pub const GpuZoneBeginLean = extern struct {
    cpuTime: i64 align(1),
    thread: u32 align(1),
    queryId: u16 align(1),
    context: u8 align(1),
};

pub const GpuZoneBegin = Extend(GpuZoneBeginLean, extern struct {
    srcloc: u64 align(1),
});

pub const GpuZoneEnd = extern struct {
    cpuTime: i64 align(1),
    thread: u32 align(1),
    queryId: u16 align(1),
    context: u8 align(1),
};

pub const GpuZoneAnnotation = extern struct {
    noteId: i64 align(1),
    value: f64 align(1),
    thread: u32 align(1),
    queryId: u16 align(1),
    context: u8 align(1),
};

pub const GpuTime = extern struct {
    gpuTime: i64 align(1),
    queryId: u16 align(1),
    context: u8 align(1),
};

pub const GpuCalibration = extern struct {
    gpuTime: i64 align(1),
    cpuTime: i64 align(1),
    cpuDelta: i64 align(1),
    context: u8 align(1),
};

pub const GpuTimeSync = extern struct {
    gpuTime: i64 align(1),
    cpuTime: i64 align(1),
    context: u8 align(1),
};

pub const GpuContextName = extern struct {
    context: u8 align(1),
};

pub const GpuContextNameFat = Extend(GpuContextName, extern struct {
    ptr: u64 align(1),
    size: u16 align(1),
});

pub const GpuAnnotationName = extern struct {
    noteId: i64 align(1),
    context: u8 align(1),
};

pub const GpuAnnotationNameFat = Extend(GpuAnnotationName, extern struct {
    ptr: u64 align(1),
    size: u16 align(1),
});

pub const MemNamePayload = extern struct {
    name: u64 align(1),
};

pub const ThreadGroupHint = extern struct {
    thread: u32 align(1),
    groupHint: i32 align(1),
};

pub const MemAlloc = extern struct {
    time: i64 align(1),
    thread: u32 align(1),
    ptr: u64 align(1),
    size: [6]u8 align(1),

    pub fn setSize(data: *MemAlloc, size: u64) void {
        std.debug.assert(size & 0xFFFF_0000_0000_0000 == 0);
        data.size = std.mem.toBytes(size)[0..6].*;
    }
};

pub const MemFree = extern struct {
    time: i64 align(1),
    thread: u32 align(1),
    ptr: u64 align(1),
};

pub const MemDiscard = extern struct {
    time: i64 align(1),
    thread: u32 align(1),
    name: u64 align(1),
};

pub const CallstackFat = extern struct {
    ptr: u64 align(1),
};

pub const CallstackFatThread = Extend(CallstackFat, extern struct {
    thread: u32 align(1),
});

pub const CallstackAllocFat = extern struct {
    ptr: u64 align(1),
    nativePtr: u64 align(1),
};

pub const CallstackAllocFatThread = Extend(CallstackAllocFat, extern struct {
    thread: u32 align(1),
});

pub const CallstackSample = extern struct {
    thread: u32 align(1),
    time: i64 align(1),
};

pub const CallstackSampleFat = Extend(CallstackSample, extern struct {
    ptr: u64 align(1),
});

pub const CallstackSample32 = extern struct {
    thread: u32 align(1),
    time: u32 align(1),
};

pub const CallstackSample16 = extern struct {
    thread: u32 align(1),
    time: u16 align(1),
};

pub const CallstackFrameSize = extern struct {
    ptr: u64 align(1),
    size: u8 align(1),
};

pub const CallstackFrameSizeFat = Extend(CallstackFrameSize, extern struct {
    data: u64 align(1),
    imageName: u64 align(1),
});

pub const CallstackFrame = extern struct {
    line: u32 align(1),
    symAddr: u64 align(1),
    symLen: u32 align(1),
};

pub const SymbolInformation = extern struct {
    line: u32 align(1),
    symAddr: u64 align(1),
};

pub const SymbolInformationFat = Extend(SymbolInformation, extern struct {
    fileString: u64 align(1),
    needFree: u8 align(1),
});

pub const CrashReport = extern struct {
    time: i64 align(1),
    text: u64 align(1), // ptr
};

pub const CrashReportThread = extern struct {
    thread: u32 align(1),
};

pub const SysTime = extern struct {
    time: i64 align(1),
    sysTime: f32 align(1),
};

pub const SysPower = extern struct {
    time: i64 align(1),
    delta: u64 align(1),
    name: u64 align(1), // ptr
};

pub const ContextSwitch = extern struct {
    time: i64 align(1),
    oldThread: u32 align(1),
    newThread: u32 align(1),
    cpu: u8 align(1),
    oldThreadWaitReason: u8 align(1),
    oldThreadState: u8 align(1),
    previousCState: u8 align(1),
    newThreadPriority: i8 align(1),
    oldThreadPriority: i8 align(1),
};

pub const ThreadWakeup = extern struct {
    time: i64 align(1),
    thread: u32 align(1),
    cpu: u8 align(1),
    adjustReason: i8 align(1),
    adjustIncrement: i8 align(1),
};

pub const TidToPid = extern struct {
    tid: u64 align(1),
    pid: u64 align(1),
};

pub const HwSample = extern struct {
    ip: u64 align(1),
    time: i64 align(1),
};

pub const PlotFormatType = enum(u8) {
    Number,
    Memory,
    Percentage,
    _,
};

pub const PlotConfig = extern struct {
    name: u64 align(1), // ptr
    type: u8 align(1),
    step: u8 align(1),
    fill: u8 align(1),
    color: u32 align(1),
};

pub const ParamSetup = extern struct {
    idx: u32 align(1),
    name: u64 align(1), // ptr
    type: u8 align(1),
    val: i32 align(1),
};

pub const SourceCodeNotAvailable = extern struct {
    id: u32 align(1),
};

pub const CpuTopology = extern struct {
    package: u32 align(1),
    die: u32 align(1),
    core: u32 align(1),
    thread: u32 align(1),
};

pub const ExternalNameMetadata = extern struct {
    thread: u64 align(1),
    name: u64 align(1),
    threadName: u64 align(1),
};

pub const SymbolCodeMetadata = extern struct {
    symbol: u64 align(1),
    ptr: u64 align(1),
    size: u32 align(1),
};

pub const SourceCodeMetadata = extern struct {
    ptr: u64 align(1),
    size: u32 align(1),
    id: u32 align(1),
};

pub const TaggedUserlandAddress = extern struct {
    storage: u64 align(1) = 0,

    const ptrShift: u64 = 8;
    const highBits: u64 = 0xFF00000000000000;

    pub fn init(addr: ?*const anyopaque, tag_val: u8) @This() {
        const addr_int: u64 = @intFromPtr(addr);
        std.debug.assert(addr_int & highBits == 0);
        return .{ .storage = addr_int << ptrShift | tag_val };
    }

    pub fn address(t: @This()) u64 {
        return t.storage >> ptrShift;
    }

    pub fn address_as(t: @This(), comptime PtrT: type) PtrT {
        return @ptrFromInt(t.address());
    }

    pub fn tag(t: @This()) u8 {
        return @intCast(t.storage & 0xFF);
    }
};

pub const ZoneBeginData = extern union {
    zone_64: Packet(ZoneBegin),
    zone_32: Packet(ZoneBegin32),
    zone_16: Packet(ZoneBegin16),

    pub fn set(data: *ZoneBeginData, dt: i64, src_loc: *const SourceLocationData) []const u8 {
        if (dt < 0) {
            data.* = .{ .zone_64 = .{ .ty = .ZoneBegin, .data = .{ .time = dt, .srcloc = @intFromPtr(src_loc) } } };
            return std.mem.asBytes(&data.zone_64);
        } else if (dt < ProtocolOffset16Bit) {
            data.* = .{ .zone_16 = .{ .ty = .ZoneBegin16, .data = .{ .time = @intCast(dt), .srcloc = @intFromPtr(src_loc) } } };
            return std.mem.asBytes(&data.zone_16);
        } else if (dt < ProtocolOffset32Bit) {
            data.* = .{ .zone_32 = .{ .ty = .ZoneBegin32, .data = .{ .time = @intCast(dt - ProtocolOffset16Bit), .srcloc = @intFromPtr(src_loc) } } };
            return std.mem.asBytes(&data.zone_32);
        } else {
            data.* = .{ .zone_64 = .{ .ty = .ZoneBegin, .data = .{ .time = dt - ProtocolOffset32Bit, .srcloc = @intFromPtr(src_loc) } } };
            return std.mem.asBytes(&data.zone_64);
        }
    }

    pub fn max_size(_: *@This()) usize {
        return @sizeOf(@This());
    }
};

pub const ZoneEndData = extern union {
    zone_64: Packet(ZoneEnd),
    zone_32: Packet(ZoneEnd32),
    zone_16: Packet(ZoneEnd16),

    pub fn set(data: *ZoneEndData, dt: i64) []const u8 {
        if (dt < 0) {
            data.* = .{ .zone_64 = .{ .ty = .ZoneEnd, .data = .{ .time = dt } } };
            return std.mem.asBytes(&data.zone_64);
        } else if (dt < ProtocolOffset16Bit) {
            data.* = .{ .zone_16 = .{ .ty = .ZoneEnd16, .data = .{ .time = @intCast(dt) } } };
            return std.mem.asBytes(&data.zone_16);
        } else if (dt < ProtocolOffset32Bit) {
            data.* = .{ .zone_32 = .{ .ty = .ZoneEnd32, .data = .{ .time = @intCast(dt - ProtocolOffset16Bit) } } };
            return std.mem.asBytes(&data.zone_32);
        } else {
            data.* = .{ .zone_64 = .{ .ty = .ZoneEnd, .data = .{ .time = dt - ProtocolOffset32Bit } } };
            return std.mem.asBytes(&data.zone_64);
        }
    }

    pub fn max_size(_: *@This()) usize {
        return @sizeOf(@This());
    }
};

pub const TrackedSMRegisterPacket = extern struct {
    ctx: Packet(ThreadContext),
    begin: Packet(ZoneBegin),

    pub fn set(self: *@This(), name: [*:0]const u8, abs_time: i64, new_state: *const SourceLocationData) []const u8 {
        self.* = .{
            .ctx = .{ .ty = .ThreadContext, .data = .{ .thread = @intFromPtr(name) } },
            // absolute time because we changed thread contexts
            .begin = .{ .ty = .ZoneBegin, .data = .{ .time = abs_time - ProtocolOffset32Bit, .srcloc = @intFromPtr(new_state) } },
        };
        return std.mem.asBytes(self);
    }
};

pub const TrackedSMUpdatePacket = extern struct {
    ctx: Packet(ThreadContext),
    end: Packet(ZoneEnd),
    begin: Packet(ZoneBegin16),

    pub fn set(self: *@This(), name: [*:0]const u8, abs_time: i64, new_state: *const SourceLocationData) []const u8 {
        self.* = .{
            .ctx = .{ .ty = .ThreadContext, .data = .{ .thread = @intFromPtr(name) } },
            // absolute time because we changed thread contexts
            .end = .{ .ty = .ZoneEnd, .data = .{ .time = abs_time - ProtocolOffset32Bit } },
            .begin = .{ .ty = .ZoneBegin16, .data = .{ .time = 0, .srcloc = @intFromPtr(new_state) } },
        };
        return std.mem.asBytes(self);
    }
};

pub const PayloadType = [Type.NUM_TYPES]type{
    Empty, // zone text
    Empty, // zone name
    MessageMetadata, // Message
    MessageColorMetadata, // MessageColor
    MessageMetadata, // MessageCallstack
    MessageColorMetadata, // MessageColorCallstack
    Message, // app info
    ZoneBeginLean, // allocated source location
    ZoneBeginLean, // allocated source location, callstack
    Empty, // callstack memory
    Empty, // callstack
    Empty, // callstack alloc
    CallstackSample,
    CallstackSample32,
    CallstackSample16,
    CallstackSample, // context switch
    CallstackSample32, // context switch
    CallstackSample16, // context switch
    FrameImage,
    ZoneBegin,
    ZoneBegin32,
    ZoneBegin16,
    ZoneBegin, // callstack
    ZoneBegin32, // callstack
    ZoneBegin16, // callstack
    ZoneEnd,
    ZoneEnd32,
    ZoneEnd16,
    LockWait,
    LockObtain,
    LockRelease,
    LockWait, // shared
    LockObtain, // shared
    LockReleaseShared,
    LockName,
    MemAlloc,
    MemAlloc, // named
    MemFree,
    MemFree, // named
    MemAlloc, // callstack
    MemAlloc, // callstack, named
    MemFree, // callstack
    MemFree, // callstack, named
    MemDiscard,
    MemDiscard, // callstack
    GpuZoneBegin,
    GpuZoneBegin, // callstack
    GpuZoneBeginLean, // allocated source location
    GpuZoneBeginLean, // allocated source location, callstack
    GpuZoneEnd,
    GpuZoneBegin, // serial
    GpuZoneBegin, // serial, callstack
    GpuZoneBeginLean, // serial, allocated source location
    GpuZoneBeginLean, // serial, allocated source location, callstack
    GpuZoneEnd, // serial
    PlotDataInt,
    PlotDataFloat,
    PlotDataDouble,
    ContextSwitch,
    ThreadWakeup,
    GpuTime,
    GpuContextName,
    GpuAnnotationName,
    CallstackFrameSize,
    SymbolInformation,
    Empty, // ExternalNameMetadata - not for wire transfer
    Empty, // SymbolCodeMetadata - not for wire transfer
    Empty, // SourceCodeMetadata - not for wire transfer
    FiberEnter,
    FiberLeave,
    SectionEnter,
    SectionLeave,
    SectionSetup,
    // above items must be first
    Empty, // terminate
    Empty, // keep alive
    ThreadContext,
    GpuCalibration,
    GpuTimeSync,
    Empty, // crash
    CrashReport,
    ZoneValidation,
    ZoneColor,
    ZoneValue,
    FrameMark, // continuous frames
    FrameMark, // start
    FrameMark, // end
    FrameVsync,
    SourceLocation,
    LockAnnounce,
    LockTerminate,
    LockMark,
    MessageLiteral,
    MessageColorLiteral,
    MessageLiteral, // callstack
    MessageColorLiteral, // callstack
    GpuNewContext,
    CallstackFrame,
    SysTime,
    SysPower,
    TidToPid,
    HwSample, // cpu cycle
    HwSample, // instruction retired
    HwSample, // cache reference
    HwSample, // cache miss
    HwSample, // branch retired
    HwSample, // branch miss
    PlotConfig,
    ParamSetup,
    Empty, // server query acknowledgement
    SourceCodeNotAvailable,
    Empty, // symbol code not available
    CpuTopology,
    Empty, // single string data
    Empty, // second string data
    Empty, // single string data, 8 bit length
    Empty, // second string data, 8 bit length
    MemNamePayload,
    ThreadGroupHint,
    GpuZoneAnnotation, // GPU zone annotation
    // keep all QueueStringTransfer below
    StringTransfer16, // string data
    StringTransfer16, // thread name
    StringTransfer16, // plot name
    StringTransfer16, // allocated source location payload
    StringTransfer, // callstack payload
    StringTransfer, // callstack alloc payload
    StringTransfer16, // frame name
    StringTransfer, // frame image data
    StringTransfer16, // external name
    StringTransfer16, // external thread name
    StringTransfer, // symbol code
    StringTransfer, // source code
    StringTransfer16, // fiber name
};

pub const PayloadSize: [Type.NUM_TYPES]usize = blk: {
    var sizes: [Type.NUM_TYPES]usize = undefined;
    for (PayloadType, &sizes) |Ty, *size| {
        size.* = @sizeOf(Ty);
    }
    break :blk sizes;
};

pub fn Packet(comptime Payload: type) type {
    return extern struct {
        ty: Type align(1),
        data: Payload align(1),
    };
}

pub const PacketSize: [Type.NUM_TYPES]usize = blk: {
    var sizes: [Type.NUM_TYPES]usize = undefined;
    for (PayloadType, &sizes) |Ty, *size| {
        size.* = @sizeOf(Packet(Ty));
    }
    break :blk sizes;
};

pub fn packet(comptime ty: Type, data: PayloadType[@backingInt(ty)]) Packet(PayloadType[@backingInt(ty)]) {
    return .{ .ty = ty, .data = data };
}

pub const MaxPacketSize = blk: {
    var max: comptime_int = 0;
    for (PacketSize) |sz| {
        max = @max(max, sz);
    }
    static_assert(max == 32, "Max packet size should be 32 per Tracy design");
    break :blk max;
};

pub const ProtocolOffset8Bit = (1 << 8);
pub const ProtocolOffset16Bit = (1 << 16);
pub const ProtocolOffset32Bit = (1 << 16) + (1 << 32);

pub const SourceLocationData = extern struct {
    name: ?[*:0]const u8,
    function: ?[*:0]const u8,
    file: ?[*:0]const u8,
    line: u32,
    color: u32,
};

/// ------------------------- Messages for Runtime comms with server ----------------------------------
pub fn Lz4CompressBound(size: u32) u32 {
    return size + (size / 255) + 16;
}

pub const ProtocolVersion: u32 = 82;
pub const BroadcastVersion: u16 = 3;

pub const lz4sz_t = u32;

pub const TargetFrameSize = 256 * 1024;
pub const LZ4Size = Lz4CompressBound(TargetFrameSize);
comptime {
    static_assert(LZ4Size <= std.math.maxInt(lz4sz_t), "LZ4Size greater than lz4sz_t");
    static_assert(TargetFrameSize * 2 >= 64 * 1024, "Not enough space for LZ4 stream buffer");
}

pub const HandshakeShibboleth = "TracyPrf";

pub const HandshakeStatus = enum(u8) {
    HandshakePending,
    HandshakeWelcome,
    HandshakeProtocolMismatch,
    HandshakeNotAvailable,
    HandshakeDropped,
    _,
};

pub const WelcomeMessageHostInfoSize = 1024;
pub const WelcomeMessageProgramNameSize = 64;

// Must increase left query space after handling!
pub const ServerQuery = enum(u8) {
    ServerQueryTerminate,
    ServerQueryString,
    ServerQueryThreadString,
    ServerQuerySourceLocation,
    ServerQueryPlotName,
    ServerQueryFrameName,
    ServerQueryParameter,
    ServerQueryFiberName,
    ServerQueryExternalName,
    // Items above are high priority. Split order must be preserved. See IsQueryPrio().
    ServerQueryDisconnect,
    ServerQueryCallstackFrame,
    ServerQuerySymbol,
    ServerQuerySymbolCode,
    ServerQuerySourceCode,
    ServerQueryDataTransfer,
    ServerQueryDataTransferPart,
    _,
};

pub const ServerQueryPacket = extern struct {
    type: ServerQuery align(1),
    ptr: u64 align(1),
    extra: u32 align(1),
};

pub const ServerQueryPacketSize = @sizeOf(ServerQueryPacket);
comptime {
    static_assert(ServerQueryPacketSize == 13, "align(1) not working properly");
}

pub const CpuArchitecture = enum(u8) {
    CpuArchUnknown,
    CpuArchX86,
    CpuArchX64,
    CpuArchArm32,
    CpuArchArm64,
    _,
};

pub const WelcomeFlags = packed struct(u8) {
    OnDemand: bool,
    IgnoreMemFaults: bool,
    CodeTransfer: bool,
    CombineSamples: bool,
    IdentifySamples: bool,
    _pad: u3 = 0,
};

pub const WelcomeMessage = extern struct {
    status: HandshakeStatus align(1) = .HandshakeWelcome,
    timerMul: f64 align(1),
    initBegin: i64 align(1),
    initEnd: i64 align(1),
    resolution: u64 align(1),
    epoch: u64 align(1),
    exectime: u64 align(1),
    pid: u64 align(1),
    samplingPeriod: i64 align(1),
    flags: WelcomeFlags align(1),
    cpuArch: CpuArchitecture align(1),
    cpuManufacturer: [12]u8 align(1),
    cpuId: u32 align(1),
    programName: [WelcomeMessageProgramNameSize]u8 align(1),
    hostInfo: [WelcomeMessageHostInfoSize]u8 align(1),
};

pub const OnDemandPayloadMessage = extern struct {
    frames: u64 align(1),
    currentTime: u64 align(1),
};

pub const BroadcastMessage = extern struct {
    broadcastVersion: u16 align(1),
    listenPort: u16 align(1),
    protocolVersion: u32 align(1),
    pid: u64 align(1),
    activeTime: i32 align(1), // in seconds
    programName: [WelcomeMessageProgramNameSize]u8 align(1),
};

pub const BroadcastMessage_v2 = extern struct {
    broadcastVersion: u16 align(1),
    listenPort: u16 align(1),
    protocolVersion: u32 align(1),
    activeTime: i32 align(1),
    programName: [WelcomeMessageProgramNameSize]u8 align(1),
};

pub const BroadcastMessage_v1 = extern struct {
    broadcastVersion: u32 align(1),
    protocolVersion: u32 align(1),
    listenPort: u32 align(1),
    activeTime: u32 align(1),
    programName: [WelcomeMessageProgramNameSize]u8 align(1),
};

pub const BroadcastMessage_v0 = extern struct {
    broadcastVersion: u32 align(1),
    protocolVersion: u32 align(1),
    activeTime: u32 align(1),
    programName: [WelcomeMessageProgramNameSize]u8 align(1),
};
