const microzig = @import("microzig");
const mmio = microzig.mmio;

const types = @import("../../types.zig");

pub const SystemControl = extern struct {
    pub const SystemControl_AIRCR__ENDIANNESS = enum(u1) {
        /// Little-endian
        VALUE_0 = 0x0,
        /// Big-endian
        VALUE_1 = 0x1,
    };

    pub const SystemControl_AIRCR__SYSRESETREQ = enum(u1) {
        /// No system reset request
        VALUE_0 = 0x0,
        /// Asserts a signal to the outer system that requests a reset
        VALUE_1 = 0x1,
    };

    pub const SystemControl_CCR__STKALIGN = enum(u1) {
        /// 4-byte aligned
        VALUE_0 = 0x0,
        /// 8-byte aligned
        VALUE_1 = 0x1,
    };

    pub const SystemControl_CCR__UNALIGN_TRP = enum(u1) {
        /// Do not trap unaligned halfword and word accesses
        VALUE_0 = 0x0,
        /// Trap unaligned halfword and word accesses
        VALUE_1 = 0x1,
    };

    pub const SystemControl_CPACR__CP10 = enum(u2) {
        /// Access denied
        DENIED = 0x0,
        /// Privileged access only
        PRIV = 0x1,
        /// Full access
        FULL = 0x3,
        _,
    };

    pub const SystemControl_CPACR__CP11 = enum(u2) {
        /// Access denied
        DENIED = 0x0,
        /// Privileged access only
        PRIV = 0x1,
        /// Full access
        FULL = 0x3,
        _,
    };

    pub const SystemControl_ICSR__NMIPENDSET = enum(u1) {
        /// Write: no effect; read: NMI exception is not pending
        VALUE_0 = 0x0,
        /// Write: changes NMI exception state to pending; read: NMI exception is pending
        VALUE_1 = 0x1,
    };

    pub const SystemControl_ICSR__PENDSTCLR = enum(u1) {
        /// No effect
        VALUE_0 = 0x0,
        /// Removes the pending state from the SysTick exception
        VALUE_1 = 0x1,
    };

    pub const SystemControl_ICSR__PENDSTSET = enum(u1) {
        /// Write: no effect; read: SysTick exception is not pending
        VALUE_0 = 0x0,
        /// Write: changes SysTick exception state to pending; read: SysTick exception is pending
        VALUE_1 = 0x1,
    };

    pub const SystemControl_ICSR__PENDSVCLR = enum(u1) {
        /// No effect
        VALUE_0 = 0x0,
        /// Removes the pending state from the PendSV exception
        VALUE_1 = 0x1,
    };

    pub const SystemControl_ICSR__PENDSVSET = enum(u1) {
        /// Write: no effect; read: PendSV exception is not pending
        VALUE_0 = 0x0,
        /// Write: changes PendSV exception state to pending; read: PendSV exception is pending
        VALUE_1 = 0x1,
    };

    pub const SystemControl_SCR__SEVONPEND = enum(u1) {
        /// Only enabled interrupts or events can wakeup the processor, disabled interrupts are excluded
        VALUE_0 = 0x0,
        /// Enabled events and all interrupts, including disabled interrupts, can wakeup the processor
        VALUE_1 = 0x1,
    };

    pub const SystemControl_SCR__SLEEPDEEP = enum(u1) {
        /// Sleep
        VALUE_0 = 0x0,
        /// Deep sleep
        VALUE_1 = 0x1,
    };

    pub const SystemControl_SCR__SLEEPONEXIT = enum(u1) {
        /// Do not sleep when returning to Thread mode
        VALUE_0 = 0x0,
        /// Enter sleep, or deep sleep, on return from an ISR
        VALUE_1 = 0x1,
    };

    /// offset: 0x00
    reserved0: [4]u8,
    /// Interrupt Controller Type Register
    /// offset: 0x04
    ICTR: mmio.Mmio(packed struct(u32) {
        INTLINESNUM: u4,
        padding: u28 = 0,
    }),
    /// Auxiliary Control Register
    /// offset: 0x08
    ACTLR: mmio.Mmio(packed struct(u32) {
        /// Disable interruption of LDM/STM instructions
        DISMCYCINT: u1,
        /// Disable wruite buffer use during default memory map accesses
        DISDEFWBUF: u1,
        /// Disable IT folding
        DISFOLD: u1,
        reserved8: u5 = 0,
        /// Disable automatic update of CONTROL.FPCA
        DISFPCA: u1,
        /// Disable out-of-order FP instructions
        DISOOFP: u1,
        padding: u22 = 0,
    }),
    /// offset: 0x0c
    reserved12: [3316]u8,
    /// CPUID Base Register
    /// offset: 0xd00
    CPUID: mmio.Mmio(packed struct(u32) {
        /// Processor revision number
        REVISION: u4,
        /// Process Part Number, 0xC24=Cortex-M4
        PARTNO: u12,
        /// Constant
        CONSTANT: u4,
        /// Variant number
        VARIANT: u4,
        /// Implementer code, 0x41=ARM
        IMPLEMENTER: u8,
    }),
    /// Interrupt Control and State Register
    /// offset: 0xd04
    ICSR: mmio.Mmio(packed struct(u32) {
        /// Active exception number
        VECTACTIVE: u9,
        reserved11: u2 = 0,
        /// No preempted active exceptions to execute
        RETTOBASE: u1,
        /// Exception number of the highest priority pending enabled exception
        VECTPENDING: u6,
        reserved22: u4 = 0,
        /// Interrupt pending flag
        ISRPENDING: u1,
        /// Debug only
        ISRPREEMPT: u1,
        reserved25: u1 = 0,
        /// SysTick clear-pending bit
        PENDSTCLR: SystemControl_ICSR__PENDSTCLR,
        /// SysTick set-pending bit
        PENDSTSET: SystemControl_ICSR__PENDSTSET,
        /// PendSV clear-pending bit
        PENDSVCLR: SystemControl_ICSR__PENDSVCLR,
        /// PendSV set-pending bit
        PENDSVSET: SystemControl_ICSR__PENDSVSET,
        reserved31: u2 = 0,
        /// NMI set-pending bit
        NMIPENDSET: SystemControl_ICSR__NMIPENDSET,
    }),
    /// Vector Table Offset Register
    /// offset: 0xd08
    VTOR: mmio.Mmio(packed struct(u32) {
        reserved7: u7 = 0,
        /// Vector table base offset
        TBLOFF: u25,
    }),
    /// Application Interrupt and Reset Control Register
    /// offset: 0xd0c
    AIRCR: mmio.Mmio(packed struct(u32) {
        /// Must write 0
        VECTRESET: u1,
        /// Must write 0
        VECTCLRACTIVE: u1,
        /// System Reset Request
        SYSRESETREQ: SystemControl_AIRCR__SYSRESETREQ,
        reserved8: u5 = 0,
        /// Interrupt priority grouping
        PRIGROUP: u3,
        reserved15: u4 = 0,
        /// Data endianness, 0=little, 1=big
        ENDIANNESS: SystemControl_AIRCR__ENDIANNESS,
        /// Register key
        VECTKEY: u16,
    }),
    /// System Control Register
    /// offset: 0xd10
    SCR: mmio.Mmio(packed struct(u32) {
        reserved1: u1 = 0,
        /// Sleep-on-exit on handler return
        SLEEPONEXIT: SystemControl_SCR__SLEEPONEXIT,
        /// Deep Sleep used as low power mode
        SLEEPDEEP: SystemControl_SCR__SLEEPDEEP,
        reserved4: u1 = 0,
        /// Send Event on Pending bit
        SEVONPEND: SystemControl_SCR__SEVONPEND,
        padding: u27 = 0,
    }),
    /// Configuration and Control Register
    /// offset: 0xd14
    CCR: mmio.Mmio(packed struct(u32) {
        /// Indicates how processor enters Thread mode
        NONBASETHRDENA: u1,
        /// Enables unprivileged software access to STIR register
        USERSETMPEND: u1,
        reserved3: u1 = 0,
        /// Enables unaligned access traps
        UNALIGN_TRP: SystemControl_CCR__UNALIGN_TRP,
        /// Enables divide by 0 trap
        DIV_0_TRP: u1,
        reserved8: u3 = 0,
        /// Ignore LDM/STM BusFault for -1/-2 priority handlers
        BFHFNMIGN: u1,
        /// Indicates stack alignment on exception entry
        STKALIGN: SystemControl_CCR__STKALIGN,
        padding: u22 = 0,
    }),
    /// System Handler Priority Register 1
    /// offset: 0xd18
    SHPR1: mmio.Mmio(packed struct(u32) {
        /// Priority of system handler 4, MemManage
        PRI_4: u8,
        /// Priority of system handler 5, BusFault
        PRI_5: u8,
        /// Priority of system handler 6, UsageFault
        PRI_6: u8,
        padding: u8 = 0,
    }),
    /// System Handler Priority Register 2
    /// offset: 0xd1c
    SHPR2: mmio.Mmio(packed struct(u32) {
        reserved24: u24 = 0,
        /// Priority of system handler 11, SVCall
        PRI_11: u8,
    }),
    /// System Handler Priority Register 3
    /// offset: 0xd20
    SHPR3: mmio.Mmio(packed struct(u32) {
        reserved16: u16 = 0,
        /// Priority of system handler 14, PendSV
        PRI_14: u8,
        /// Priority of system handler 15, SysTick exception
        PRI_15: u8,
    }),
    /// System Handler Control and State Register
    /// offset: 0xd24
    SHCSR: mmio.Mmio(packed struct(u32) {
        /// MemManage exception active bit
        MEMFAULTACT: u1,
        /// BusFault exception active bit
        BUSFAULTACT: u1,
        reserved3: u1 = 0,
        /// UsageFault exception active bit
        USGFAULTACT: u1,
        reserved7: u3 = 0,
        /// SVCall active bit
        SVCALLACT: u1,
        /// DebugMonitor exception active bit
        MONITORACT: u1,
        reserved10: u1 = 0,
        /// PendSV exception active bit
        PENDSVACT: u1,
        /// SysTick exception active bit
        SYSTICKACT: u1,
        /// UsageFault exception pending bit
        USGFAULTPENDED: u1,
        /// MemManage exception pending bit
        MEMFAULTPENDED: u1,
        /// BusFault exception pending bit
        BUSFAULTPENDED: u1,
        /// SVCall pending bit
        SVCALLPENDED: u1,
        /// MemManage enable bit
        MEMFAULTENA: u1,
        /// BusFault enable bit
        BUSFAULTENA: u1,
        /// UsageFault enable bit
        USGFAULTENA: u1,
        padding: u13 = 0,
    }),
    /// Configurable Fault Status Register
    /// offset: 0xd28
    CFSR: mmio.Mmio(packed struct(u32) {
        /// Instruction access violation
        IACCVIOL: u1,
        /// Data access violation
        DACCVIOL: u1,
        reserved3: u1 = 0,
        /// MemManage Fault on unstacking for exception return
        MUNSTKERR: u1,
        /// MemManage Fault on stacking for exception entry
        MSTKERR: u1,
        /// MemManager Fault occured during FP lazy state preservation
        MLSPERR: u1,
        reserved7: u1 = 0,
        /// MemManage Fault Address Register valid
        MMARVALID: u1,
        /// Instruction bus error
        IBUSERR: u1,
        /// Precise data bus error
        PRECISERR: u1,
        /// Imprecise data bus error
        IMPRECISERR: u1,
        /// BusFault on unstacking for exception return
        UNSTKERR: u1,
        /// BusFault on stacking for exception entry
        STKERR: u1,
        /// BusFault occured during FP lazy state preservation
        LSPERR: u1,
        reserved15: u1 = 0,
        /// BusFault Address Register valid
        BFARVALID: u1,
        /// Undefined instruction UsageFault
        UNDEFINSTR: u1,
        /// Invalid state UsageFault
        INVSTATE: u1,
        /// Invalid PC load UsageFault
        INVPC: u1,
        /// No coprocessor UsageFault
        NOCP: u1,
        reserved24: u4 = 0,
        /// Unaligned access UsageFault
        UNALIGNED: u1,
        /// Divide by zero UsageFault
        DIVBYZERO: u1,
        padding: u6 = 0,
    }),
    /// HardFault Status Register
    /// offset: 0xd2c
    HFSR: mmio.Mmio(packed struct(u32) {
        reserved1: u1 = 0,
        /// BusFault on a Vector Table read during exception processing
        VECTTBL: u1,
        reserved30: u28 = 0,
        /// Forced Hard Fault
        FORCED: u1,
        /// Debug: always write 0
        DEBUGEVT: u1,
    }),
    /// Debug Fault Status Register
    /// offset: 0xd30
    DFSR: mmio.Mmio(packed struct(u32) {
        HALTED: u1,
        BKPT: u1,
        DWTTRAP: u1,
        VCATCH: u1,
        EXTERNAL: u1,
        padding: u27 = 0,
    }),
    /// MemManage Fault Address Register
    /// offset: 0xd34
    MMFAR: mmio.Mmio(packed struct(u32) {
        /// Address that generated the MemManage fault
        ADDRESS: u32,
    }),
    /// BusFault Address Register
    /// offset: 0xd38
    BFAR: mmio.Mmio(packed struct(u32) {
        /// Address that generated the BusFault
        ADDRESS: u32,
    }),
    /// Auxiliary Fault Status Register
    /// offset: 0xd3c
    AFSR: mmio.Mmio(packed struct(u32) {
        /// AUXFAULT input signals
        IMPDEF: u32,
    }),
    /// Processor Feature Register
    /// offset: 0xd40
    PFR: [2]u32,
    /// Debug Feature Register
    /// offset: 0xd48
    DFR: u32,
    /// Auxiliary Feature Register
    /// offset: 0xd4c
    ADR: u32,
    /// Memory Model Feature Register
    /// offset: 0xd50
    MMFR: [4]u32,
    /// Instruction Set Attributes Register
    /// offset: 0xd60
    ISAR: [5]u32,
    /// offset: 0xd74
    reserved3444: [20]u8,
    /// Coprocessor Access Control Register
    /// offset: 0xd88
    CPACR: mmio.Mmio(packed struct(u32) {
        reserved20: u20 = 0,
        /// Access privileges for coprocessor 10
        CP10: SystemControl_CPACR__CP10,
        /// Access privileges for coprocessor 11
        CP11: SystemControl_CPACR__CP11,
        padding: u8 = 0,
    }),
};
