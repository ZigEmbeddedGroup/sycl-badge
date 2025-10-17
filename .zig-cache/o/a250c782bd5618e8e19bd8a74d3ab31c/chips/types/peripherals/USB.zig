const microzig = @import("microzig");
const mmio = microzig.mmio;

const types = @import("../../types.zig");

pub const USB_CTRLA__MODE = enum(u1) {
    /// Device Mode
    DEVICE = 0x0,
    /// Host Mode
    HOST = 0x1,
};

pub const USB_DEVICE_CTRLB__LPMHDSK = enum(u2) {
    /// No handshake. LPM is not supported
    NO = 0x0,
    /// ACK
    ACK = 0x1,
    /// NYET
    NYET = 0x2,
    /// STALL
    STALL = 0x3,
};

pub const USB_DEVICE_CTRLB__SPDCONF = enum(u2) {
    /// FS : Full Speed
    FS = 0x0,
    /// LS : Low Speed
    LS = 0x1,
    /// HS : High Speed capable
    HS = 0x2,
    /// HSTM: High Speed Test Mode (force high-speed mode for test mode)
    HSTM = 0x3,
};

pub const USB_DEVICE_STATUS__LINESTATE = enum(u2) {
    /// SE0/RESET
    @"0" = 0x0,
    /// FS-J or LS-K State
    @"1" = 0x1,
    /// FS-K or LS-J State
    @"2" = 0x2,
    _,
};

pub const USB_DEVICE_STATUS__SPEED = enum(u2) {
    /// Full-speed mode
    FS = 0x0,
    /// Low-speed mode
    LS = 0x1,
    /// High-speed mode
    HS = 0x2,
    _,
};

pub const USB_FSMSTATUS__FSMSTATE = enum(u7) {
    /// OFF (L3). It corresponds to the powered-off, disconnected, and disabled state
    OFF = 0x1,
    /// ON (L0). It corresponds to the Idle and Active states
    ON = 0x2,
    /// SUSPEND (L2)
    SUSPEND = 0x4,
    /// SLEEP (L1)
    SLEEP = 0x8,
    /// DNRESUME. Down Stream Resume.
    DNRESUME = 0x10,
    /// UPRESUME. Up Stream Resume.
    UPRESUME = 0x20,
    /// RESET. USB lines Reset.
    RESET = 0x40,
    _,
};

pub const USB_HOST_CTRLB__SPDCONF = enum(u2) {
    /// Normal mode: the host starts in full-speed mode and performs a high-speed reset to switch to the high speed mode if the downstream peripheral is high-speed capable.
    NORMAL = 0x0,
    /// Full-speed: the host remains in full-speed mode whatever is the peripheral speed capability. Relevant in UTMI mode only.
    FS = 0x3,
    _,
};

pub const DEVICE_DESC_BANK = extern union {
    pub const Mode = enum {
        DEVICE,
    };

    pub fn get_mode(self: *volatile @This()) Mode {
        {
            const value = self.CTRLA.read().MODE;
            switch (value) {
                0,
                => return .DEVICE,
                else => {},
            }
        }

        unreachable;
    }

    DEVICE: extern struct {
        /// DEVICE_DESC_BANK Endpoint Bank, Adress of Data Buffer
        /// offset: 0x00
        ADDR: mmio.Mmio(packed struct(u32) {
            /// Adress of data buffer
            ADDR: u32,
        }),
        /// DEVICE_DESC_BANK Endpoint Bank, Packet Size
        /// offset: 0x04
        PCKSIZE: mmio.Mmio(packed struct(u32) {
            /// Byte Count
            BYTE_COUNT: u14,
            /// Multi Packet In or Out size
            MULTI_PACKET_SIZE: u14,
            /// Enpoint size
            SIZE: u3,
            /// Automatic Zero Length Packet
            AUTO_ZLP: u1,
        }),
        /// DEVICE_DESC_BANK Endpoint Bank, Extended
        /// offset: 0x08
        EXTREG: mmio.Mmio(packed struct(u16) {
            /// SUBPID field send with extended token
            SUBPID: u4,
            /// Variable field send with extended token
            VARIABLE: u11,
            padding: u1 = 0,
        }),
        /// DEVICE_DESC_BANK Enpoint Bank, Status of Bank
        /// offset: 0x0a
        STATUS_BK: mmio.Mmio(packed struct(u8) {
            /// CRC Error Status
            CRCERR: u1,
            /// Error Flow Status
            ERRORFLOW: u1,
            padding: u6 = 0,
        }),
        padding: [5]u8,
    },
};

pub const DEVICE_ENDPOINT = extern union {
    pub const Mode = enum {
        DEVICE,
    };

    pub fn get_mode(self: *volatile @This()) Mode {
        {
            const value = self.CTRLA.read().MODE;
            switch (value) {
                0,
                => return .DEVICE,
                else => {},
            }
        }

        unreachable;
    }

    DEVICE: extern struct {
        /// DEVICE_ENDPOINT End Point Configuration
        /// offset: 0x00
        EPCFG: mmio.Mmio(packed struct(u8) {
            /// End Point Type0
            EPTYPE0: u3,
            reserved4: u1 = 0,
            /// End Point Type1
            EPTYPE1: u3,
            /// NYET Token Disable
            NYETDIS: u1,
        }),
        /// offset: 0x01
        reserved1: [3]u8,
        /// DEVICE_ENDPOINT End Point Pipe Status Clear
        /// offset: 0x04
        EPSTATUSCLR: mmio.Mmio(packed struct(u8) {
            /// Data Toggle OUT Clear
            DTGLOUT: u1,
            /// Data Toggle IN Clear
            DTGLIN: u1,
            /// Current Bank Clear
            CURBK: u1,
            reserved4: u1 = 0,
            /// Stall 0 Request Clear
            STALLRQ0: u1,
            /// Stall 1 Request Clear
            STALLRQ1: u1,
            /// Bank 0 Ready Clear
            BK0RDY: u1,
            /// Bank 1 Ready Clear
            BK1RDY: u1,
        }),
        /// DEVICE_ENDPOINT End Point Pipe Status Set
        /// offset: 0x05
        EPSTATUSSET: mmio.Mmio(packed struct(u8) {
            /// Data Toggle OUT Set
            DTGLOUT: u1,
            /// Data Toggle IN Set
            DTGLIN: u1,
            /// Current Bank Set
            CURBK: u1,
            reserved4: u1 = 0,
            /// Stall 0 Request Set
            STALLRQ0: u1,
            /// Stall 1 Request Set
            STALLRQ1: u1,
            /// Bank 0 Ready Set
            BK0RDY: u1,
            /// Bank 1 Ready Set
            BK1RDY: u1,
        }),
        /// DEVICE_ENDPOINT End Point Pipe Status
        /// offset: 0x06
        EPSTATUS: mmio.Mmio(packed struct(u8) {
            /// Data Toggle Out
            DTGLOUT: u1,
            /// Data Toggle In
            DTGLIN: u1,
            /// Current Bank
            CURBK: u1,
            reserved4: u1 = 0,
            /// Stall 0 Request
            STALLRQ0: u1,
            /// Stall 1 Request
            STALLRQ1: u1,
            /// Bank 0 ready
            BK0RDY: u1,
            /// Bank 1 ready
            BK1RDY: u1,
        }),
        /// DEVICE_ENDPOINT End Point Interrupt Flag
        /// offset: 0x07
        EPINTFLAG: mmio.Mmio(packed struct(u8) {
            /// Transfer Complete 0
            TRCPT0: u1,
            /// Transfer Complete 1
            TRCPT1: u1,
            /// Error Flow 0
            TRFAIL0: u1,
            /// Error Flow 1
            TRFAIL1: u1,
            /// Received Setup
            RXSTP: u1,
            /// Stall 0 In/out
            STALL0: u1,
            /// Stall 1 In/out
            STALL1: u1,
            padding: u1 = 0,
        }),
        /// DEVICE_ENDPOINT End Point Interrupt Clear Flag
        /// offset: 0x08
        EPINTENCLR: mmio.Mmio(packed struct(u8) {
            /// Transfer Complete 0 Interrupt Disable
            TRCPT0: u1,
            /// Transfer Complete 1 Interrupt Disable
            TRCPT1: u1,
            /// Error Flow 0 Interrupt Disable
            TRFAIL0: u1,
            /// Error Flow 1 Interrupt Disable
            TRFAIL1: u1,
            /// Received Setup Interrupt Disable
            RXSTP: u1,
            /// Stall 0 In/Out Interrupt Disable
            STALL0: u1,
            /// Stall 1 In/Out Interrupt Disable
            STALL1: u1,
            padding: u1 = 0,
        }),
        /// DEVICE_ENDPOINT End Point Interrupt Set Flag
        /// offset: 0x09
        EPINTENSET: mmio.Mmio(packed struct(u8) {
            /// Transfer Complete 0 Interrupt Enable
            TRCPT0: u1,
            /// Transfer Complete 1 Interrupt Enable
            TRCPT1: u1,
            /// Error Flow 0 Interrupt Enable
            TRFAIL0: u1,
            /// Error Flow 1 Interrupt Enable
            TRFAIL1: u1,
            /// Received Setup Interrupt Enable
            RXSTP: u1,
            /// Stall 0 In/out Interrupt enable
            STALL0: u1,
            /// Stall 1 In/out Interrupt enable
            STALL1: u1,
            padding: u1 = 0,
        }),
        padding: [22]u8,
    },
};

pub const HOST_DESC_BANK = extern union {
    pub const Mode = enum {
        HOST,
    };

    pub fn get_mode(self: *volatile @This()) Mode {
        {
            const value = self.CTRLA.read().MODE;
            switch (value) {
                1,
                => return .HOST,
                else => {},
            }
        }

        unreachable;
    }

    HOST: extern struct {
        /// HOST_DESC_BANK Host Bank, Adress of Data Buffer
        /// offset: 0x00
        ADDR: mmio.Mmio(packed struct(u32) {
            /// Adress of data buffer
            ADDR: u32,
        }),
        /// HOST_DESC_BANK Host Bank, Packet Size
        /// offset: 0x04
        PCKSIZE: mmio.Mmio(packed struct(u32) {
            /// Byte Count
            BYTE_COUNT: u14,
            /// Multi Packet In or Out size
            MULTI_PACKET_SIZE: u14,
            /// Pipe size
            SIZE: u3,
            /// Automatic Zero Length Packet
            AUTO_ZLP: u1,
        }),
        /// HOST_DESC_BANK Host Bank, Extended
        /// offset: 0x08
        EXTREG: mmio.Mmio(packed struct(u16) {
            /// SUBPID field send with extended token
            SUBPID: u4,
            /// Variable field send with extended token
            VARIABLE: u11,
            padding: u1 = 0,
        }),
        /// HOST_DESC_BANK Host Bank, Status of Bank
        /// offset: 0x0a
        STATUS_BK: mmio.Mmio(packed struct(u8) {
            /// CRC Error Status
            CRCERR: u1,
            /// Error Flow Status
            ERRORFLOW: u1,
            padding: u6 = 0,
        }),
        /// offset: 0x0b
        reserved11: [1]u8,
        /// HOST_DESC_BANK Host Bank, Host Control Pipe
        /// offset: 0x0c
        CTRL_PIPE: mmio.Mmio(packed struct(u16) {
            /// Pipe Device Adress
            PDADDR: u7,
            reserved8: u1 = 0,
            /// Pipe Endpoint Number
            PEPNUM: u4,
            /// Pipe Error Max Number
            PERMAX: u4,
        }),
        /// HOST_DESC_BANK Host Bank, Host Status Pipe
        /// offset: 0x0e
        STATUS_PIPE: mmio.Mmio(packed struct(u16) {
            /// Data Toggle Error
            DTGLER: u1,
            /// Data PID Error
            DAPIDER: u1,
            /// PID Error
            PIDER: u1,
            /// Time Out Error
            TOUTER: u1,
            /// CRC16 Error
            CRC16ER: u1,
            /// Pipe Error Count
            ERCNT: u3,
            padding: u8 = 0,
        }),
    },
};

pub const HOST_PIPE = extern union {
    pub const Mode = enum {
        HOST,
    };

    pub fn get_mode(self: *volatile @This()) Mode {
        {
            const value = self.CTRLA.read().MODE;
            switch (value) {
                1,
                => return .HOST,
                else => {},
            }
        }

        unreachable;
    }

    HOST: extern struct {
        /// HOST_PIPE End Point Configuration
        /// offset: 0x00
        PCFG: mmio.Mmio(packed struct(u8) {
            /// Pipe Token
            PTOKEN: u2,
            /// Pipe Bank
            BK: u1,
            /// Pipe Type
            PTYPE: u3,
            padding: u2 = 0,
        }),
        /// offset: 0x01
        reserved1: [2]u8,
        /// HOST_PIPE Bus Access Period of Pipe
        /// offset: 0x03
        BINTERVAL: mmio.Mmio(packed struct(u8) {
            /// Bit Interval
            BITINTERVAL: u8,
        }),
        /// HOST_PIPE End Point Pipe Status Clear
        /// offset: 0x04
        PSTATUSCLR: mmio.Mmio(packed struct(u8) {
            /// Data Toggle clear
            DTGL: u1,
            reserved2: u1 = 0,
            /// Curren Bank clear
            CURBK: u1,
            reserved4: u1 = 0,
            /// Pipe Freeze Clear
            PFREEZE: u1,
            reserved6: u1 = 0,
            /// Bank 0 Ready Clear
            BK0RDY: u1,
            /// Bank 1 Ready Clear
            BK1RDY: u1,
        }),
        /// HOST_PIPE End Point Pipe Status Set
        /// offset: 0x05
        PSTATUSSET: mmio.Mmio(packed struct(u8) {
            /// Data Toggle Set
            DTGL: u1,
            reserved2: u1 = 0,
            /// Current Bank Set
            CURBK: u1,
            reserved4: u1 = 0,
            /// Pipe Freeze Set
            PFREEZE: u1,
            reserved6: u1 = 0,
            /// Bank 0 Ready Set
            BK0RDY: u1,
            /// Bank 1 Ready Set
            BK1RDY: u1,
        }),
        /// HOST_PIPE End Point Pipe Status
        /// offset: 0x06
        PSTATUS: mmio.Mmio(packed struct(u8) {
            /// Data Toggle
            DTGL: u1,
            reserved2: u1 = 0,
            /// Current Bank
            CURBK: u1,
            reserved4: u1 = 0,
            /// Pipe Freeze
            PFREEZE: u1,
            reserved6: u1 = 0,
            /// Bank 0 ready
            BK0RDY: u1,
            /// Bank 1 ready
            BK1RDY: u1,
        }),
        /// HOST_PIPE Pipe Interrupt Flag
        /// offset: 0x07
        PINTFLAG: mmio.Mmio(packed struct(u8) {
            /// Transfer Complete 0 Interrupt Flag
            TRCPT0: u1,
            /// Transfer Complete 1 Interrupt Flag
            TRCPT1: u1,
            /// Error Flow Interrupt Flag
            TRFAIL: u1,
            /// Pipe Error Interrupt Flag
            PERR: u1,
            /// Transmit Setup Interrupt Flag
            TXSTP: u1,
            /// Stall Interrupt Flag
            STALL: u1,
            padding: u2 = 0,
        }),
        /// HOST_PIPE Pipe Interrupt Flag Clear
        /// offset: 0x08
        PINTENCLR: mmio.Mmio(packed struct(u8) {
            /// Transfer Complete 0 Disable
            TRCPT0: u1,
            /// Transfer Complete 1 Disable
            TRCPT1: u1,
            /// Error Flow Interrupt Disable
            TRFAIL: u1,
            /// Pipe Error Interrupt Disable
            PERR: u1,
            /// Transmit Setup Interrupt Disable
            TXSTP: u1,
            /// Stall Inetrrupt Disable
            STALL: u1,
            padding: u2 = 0,
        }),
        /// HOST_PIPE Pipe Interrupt Flag Set
        /// offset: 0x09
        PINTENSET: mmio.Mmio(packed struct(u8) {
            /// Transfer Complete 0 Interrupt Enable
            TRCPT0: u1,
            /// Transfer Complete 1 Interrupt Enable
            TRCPT1: u1,
            /// Error Flow Interrupt Enable
            TRFAIL: u1,
            /// Pipe Error Interrupt Enable
            PERR: u1,
            /// Transmit Setup Interrupt Enable
            TXSTP: u1,
            /// Stall Interrupt Enable
            STALL: u1,
            padding: u2 = 0,
        }),
        padding: [22]u8,
    },
};

/// Universal Serial Bus
pub const USB = extern union {
    pub const Mode = enum {
        DEVICE,
        HOST,
    };

    pub fn get_mode(self: *volatile @This()) Mode {
        {
            const value = self.CTRLA.read().MODE;
            switch (value) {
                0,
                => return .DEVICE,
                else => {},
            }
        }
        {
            const value = self.CTRLA.read().MODE;
            switch (value) {
                1,
                => return .HOST,
                else => {},
            }
        }

        unreachable;
    }

    DEVICE: extern struct {
        /// Control A
        /// offset: 0x00
        CTRLA: mmio.Mmio(packed struct(u8) {
            /// Software Reset
            SWRST: u1,
            /// Enable
            ENABLE: u1,
            /// Run in Standby Mode
            RUNSTDBY: u1,
            reserved7: u4 = 0,
            /// Operating Mode
            MODE: USB_CTRLA__MODE,
        }),
        /// offset: 0x01
        reserved1: [1]u8,
        /// Synchronization Busy
        /// offset: 0x02
        SYNCBUSY: mmio.Mmio(packed struct(u8) {
            /// Software Reset Synchronization Busy
            SWRST: u1,
            /// Enable Synchronization Busy
            ENABLE: u1,
            padding: u6 = 0,
        }),
        /// USB Quality Of Service
        /// offset: 0x03
        QOSCTRL: mmio.Mmio(packed struct(u8) {
            /// Configuration Quality of Service
            CQOS: u2,
            /// Data Quality of Service
            DQOS: u2,
            padding: u4 = 0,
        }),
        /// offset: 0x04
        reserved4: [4]u8,
        /// DEVICE Control B
        /// offset: 0x08
        CTRLB: mmio.Mmio(packed struct(u16) {
            /// Detach
            DETACH: u1,
            /// Upstream Resume
            UPRSM: u1,
            /// Speed Configuration
            SPDCONF: USB_DEVICE_CTRLB__SPDCONF,
            /// No Reply
            NREPLY: u1,
            /// Test mode J
            TSTJ: u1,
            /// Test mode K
            TSTK: u1,
            /// Test packet mode
            TSTPCKT: u1,
            /// Specific Operational Mode
            OPMODE2: u1,
            /// Global NAK
            GNAK: u1,
            /// Link Power Management Handshake
            LPMHDSK: USB_DEVICE_CTRLB__LPMHDSK,
            padding: u4 = 0,
        }),
        /// DEVICE Device Address
        /// offset: 0x0a
        DADD: mmio.Mmio(packed struct(u8) {
            /// Device Address
            DADD: u7,
            /// Device Address Enable
            ADDEN: u1,
        }),
        /// offset: 0x0b
        reserved11: [1]u8,
        /// DEVICE Status
        /// offset: 0x0c
        STATUS: mmio.Mmio(packed struct(u8) {
            reserved2: u2 = 0,
            /// Speed Status
            SPEED: USB_DEVICE_STATUS__SPEED,
            reserved6: u2 = 0,
            /// USB Line State Status
            LINESTATE: USB_DEVICE_STATUS__LINESTATE,
        }),
        /// Finite State Machine Status
        /// offset: 0x0d
        FSMSTATUS: mmio.Mmio(packed struct(u8) {
            /// Fine State Machine Status
            FSMSTATE: USB_FSMSTATUS__FSMSTATE,
            padding: u1 = 0,
        }),
        /// offset: 0x0e
        reserved14: [2]u8,
        /// DEVICE Device Frame Number
        /// offset: 0x10
        FNUM: mmio.Mmio(packed struct(u16) {
            /// Micro Frame Number
            MFNUM: u3,
            /// Frame Number
            FNUM: u11,
            reserved15: u1 = 0,
            /// Frame Number CRC Error
            FNCERR: u1,
        }),
        /// offset: 0x12
        reserved18: [2]u8,
        /// DEVICE Device Interrupt Enable Clear
        /// offset: 0x14
        INTENCLR: mmio.Mmio(packed struct(u16) {
            /// Suspend Interrupt Enable
            SUSPEND: u1,
            /// Micro Start of Frame Interrupt Enable in High Speed Mode
            MSOF: u1,
            /// Start Of Frame Interrupt Enable
            SOF: u1,
            /// End of Reset Interrupt Enable
            EORST: u1,
            /// Wake Up Interrupt Enable
            WAKEUP: u1,
            /// End Of Resume Interrupt Enable
            EORSM: u1,
            /// Upstream Resume Interrupt Enable
            UPRSM: u1,
            /// Ram Access Interrupt Enable
            RAMACER: u1,
            /// Link Power Management Not Yet Interrupt Enable
            LPMNYET: u1,
            /// Link Power Management Suspend Interrupt Enable
            LPMSUSP: u1,
            padding: u6 = 0,
        }),
        /// offset: 0x16
        reserved22: [2]u8,
        /// DEVICE Device Interrupt Enable Set
        /// offset: 0x18
        INTENSET: mmio.Mmio(packed struct(u16) {
            /// Suspend Interrupt Enable
            SUSPEND: u1,
            /// Micro Start of Frame Interrupt Enable in High Speed Mode
            MSOF: u1,
            /// Start Of Frame Interrupt Enable
            SOF: u1,
            /// End of Reset Interrupt Enable
            EORST: u1,
            /// Wake Up Interrupt Enable
            WAKEUP: u1,
            /// End Of Resume Interrupt Enable
            EORSM: u1,
            /// Upstream Resume Interrupt Enable
            UPRSM: u1,
            /// Ram Access Interrupt Enable
            RAMACER: u1,
            /// Link Power Management Not Yet Interrupt Enable
            LPMNYET: u1,
            /// Link Power Management Suspend Interrupt Enable
            LPMSUSP: u1,
            padding: u6 = 0,
        }),
        /// offset: 0x1a
        reserved26: [2]u8,
        /// DEVICE Device Interrupt Flag
        /// offset: 0x1c
        INTFLAG: mmio.Mmio(packed struct(u16) {
            /// Suspend
            SUSPEND: u1,
            /// Micro Start of Frame in High Speed Mode
            MSOF: u1,
            /// Start Of Frame
            SOF: u1,
            /// End of Reset
            EORST: u1,
            /// Wake Up
            WAKEUP: u1,
            /// End Of Resume
            EORSM: u1,
            /// Upstream Resume
            UPRSM: u1,
            /// Ram Access
            RAMACER: u1,
            /// Link Power Management Not Yet
            LPMNYET: u1,
            /// Link Power Management Suspend
            LPMSUSP: u1,
            padding: u6 = 0,
        }),
        /// offset: 0x1e
        reserved30: [2]u8,
        /// DEVICE End Point Interrupt Summary
        /// offset: 0x20
        EPINTSMRY: mmio.Mmio(packed struct(u16) {
            /// End Point 0 Interrupt
            EPINT0: u1,
            /// End Point 1 Interrupt
            EPINT1: u1,
            /// End Point 2 Interrupt
            EPINT2: u1,
            /// End Point 3 Interrupt
            EPINT3: u1,
            /// End Point 4 Interrupt
            EPINT4: u1,
            /// End Point 5 Interrupt
            EPINT5: u1,
            /// End Point 6 Interrupt
            EPINT6: u1,
            /// End Point 7 Interrupt
            EPINT7: u1,
            padding: u8 = 0,
        }),
        /// offset: 0x22
        reserved34: [2]u8,
        /// Descriptor Address
        /// offset: 0x24
        DESCADD: mmio.Mmio(packed struct(u32) {
            /// Descriptor Address Value
            DESCADD: u32,
        }),
        /// USB PAD Calibration
        /// offset: 0x28
        PADCAL: mmio.Mmio(packed struct(u16) {
            /// USB Pad Transp calibration
            TRANSP: u5,
            reserved6: u1 = 0,
            /// USB Pad Transn calibration
            TRANSN: u5,
            reserved12: u1 = 0,
            /// USB Pad Trim calibration
            TRIM: u3,
            padding: u1 = 0,
        }),
    },
    HOST: extern struct {
        /// Control A
        /// offset: 0x00
        CTRLA: mmio.Mmio(packed struct(u8) {
            /// Software Reset
            SWRST: u1,
            /// Enable
            ENABLE: u1,
            /// Run in Standby Mode
            RUNSTDBY: u1,
            reserved7: u4 = 0,
            /// Operating Mode
            MODE: USB_CTRLA__MODE,
        }),
        /// offset: 0x01
        reserved1: [1]u8,
        /// Synchronization Busy
        /// offset: 0x02
        SYNCBUSY: mmio.Mmio(packed struct(u8) {
            /// Software Reset Synchronization Busy
            SWRST: u1,
            /// Enable Synchronization Busy
            ENABLE: u1,
            padding: u6 = 0,
        }),
        /// USB Quality Of Service
        /// offset: 0x03
        QOSCTRL: mmio.Mmio(packed struct(u8) {
            /// Configuration Quality of Service
            CQOS: u2,
            /// Data Quality of Service
            DQOS: u2,
            padding: u4 = 0,
        }),
        /// offset: 0x04
        reserved4: [4]u8,
        /// HOST Control B
        /// offset: 0x08
        CTRLB: mmio.Mmio(packed struct(u16) {
            reserved1: u1 = 0,
            /// Send USB Resume
            RESUME: u1,
            /// Speed Configuration for Host
            SPDCONF: USB_HOST_CTRLB__SPDCONF,
            /// Auto Resume Enable
            AUTORESUME: u1,
            /// Test mode J
            TSTJ: u1,
            /// Test mode K
            TSTK: u1,
            reserved8: u1 = 0,
            /// Start of Frame Generation Enable
            SOFE: u1,
            /// Send USB Reset
            BUSRESET: u1,
            /// VBUS is OK
            VBUSOK: u1,
            /// Send L1 Resume
            L1RESUME: u1,
            padding: u4 = 0,
        }),
        /// HOST Host Start Of Frame Control
        /// offset: 0x0a
        HSOFC: mmio.Mmio(packed struct(u8) {
            /// Frame Length Control
            FLENC: u4,
            reserved7: u3 = 0,
            /// Frame Length Control Enable
            FLENCE: u1,
        }),
        /// offset: 0x0b
        reserved11: [1]u8,
        /// HOST Status
        /// offset: 0x0c
        STATUS: mmio.Mmio(packed struct(u8) {
            reserved2: u2 = 0,
            /// Speed Status
            SPEED: u2,
            reserved6: u2 = 0,
            /// USB Line State Status
            LINESTATE: u2,
        }),
        /// Finite State Machine Status
        /// offset: 0x0d
        FSMSTATUS: mmio.Mmio(packed struct(u8) {
            /// Fine State Machine Status
            FSMSTATE: USB_FSMSTATUS__FSMSTATE,
            padding: u1 = 0,
        }),
        /// offset: 0x0e
        reserved14: [2]u8,
        /// HOST Host Frame Number
        /// offset: 0x10
        FNUM: mmio.Mmio(packed struct(u16) {
            /// Micro Frame Number
            MFNUM: u3,
            /// Frame Number
            FNUM: u11,
            padding: u2 = 0,
        }),
        /// HOST Host Frame Length
        /// offset: 0x12
        FLENHIGH: mmio.Mmio(packed struct(u8) {
            /// Frame Length
            FLENHIGH: u8,
        }),
        /// offset: 0x13
        reserved19: [1]u8,
        /// HOST Host Interrupt Enable Clear
        /// offset: 0x14
        INTENCLR: mmio.Mmio(packed struct(u16) {
            reserved2: u2 = 0,
            /// Host Start Of Frame Interrupt Disable
            HSOF: u1,
            /// BUS Reset Interrupt Disable
            RST: u1,
            /// Wake Up Interrupt Disable
            WAKEUP: u1,
            /// DownStream to Device Interrupt Disable
            DNRSM: u1,
            /// Upstream Resume from Device Interrupt Disable
            UPRSM: u1,
            /// Ram Access Interrupt Disable
            RAMACER: u1,
            /// Device Connection Interrupt Disable
            DCONN: u1,
            /// Device Disconnection Interrupt Disable
            DDISC: u1,
            padding: u6 = 0,
        }),
        /// offset: 0x16
        reserved22: [2]u8,
        /// HOST Host Interrupt Enable Set
        /// offset: 0x18
        INTENSET: mmio.Mmio(packed struct(u16) {
            reserved2: u2 = 0,
            /// Host Start Of Frame Interrupt Enable
            HSOF: u1,
            /// Bus Reset Interrupt Enable
            RST: u1,
            /// Wake Up Interrupt Enable
            WAKEUP: u1,
            /// DownStream to the Device Interrupt Enable
            DNRSM: u1,
            /// Upstream Resume fromthe device Interrupt Enable
            UPRSM: u1,
            /// Ram Access Interrupt Enable
            RAMACER: u1,
            /// Link Power Management Interrupt Enable
            DCONN: u1,
            /// Device Disconnection Interrupt Enable
            DDISC: u1,
            padding: u6 = 0,
        }),
        /// offset: 0x1a
        reserved26: [2]u8,
        /// HOST Host Interrupt Flag
        /// offset: 0x1c
        INTFLAG: mmio.Mmio(packed struct(u16) {
            reserved2: u2 = 0,
            /// Host Start Of Frame
            HSOF: u1,
            /// Bus Reset
            RST: u1,
            /// Wake Up
            WAKEUP: u1,
            /// Downstream
            DNRSM: u1,
            /// Upstream Resume from the Device
            UPRSM: u1,
            /// Ram Access
            RAMACER: u1,
            /// Device Connection
            DCONN: u1,
            /// Device Disconnection
            DDISC: u1,
            padding: u6 = 0,
        }),
        /// offset: 0x1e
        reserved30: [2]u8,
        /// HOST Pipe Interrupt Summary
        /// offset: 0x20
        PINTSMRY: mmio.Mmio(packed struct(u16) {
            /// Pipe 0 Interrupt
            EPINT0: u1,
            /// Pipe 1 Interrupt
            EPINT1: u1,
            /// Pipe 2 Interrupt
            EPINT2: u1,
            /// Pipe 3 Interrupt
            EPINT3: u1,
            /// Pipe 4 Interrupt
            EPINT4: u1,
            /// Pipe 5 Interrupt
            EPINT5: u1,
            /// Pipe 6 Interrupt
            EPINT6: u1,
            /// Pipe 7 Interrupt
            EPINT7: u1,
            padding: u8 = 0,
        }),
        /// offset: 0x22
        reserved34: [2]u8,
        /// Descriptor Address
        /// offset: 0x24
        DESCADD: mmio.Mmio(packed struct(u32) {
            /// Descriptor Address Value
            DESCADD: u32,
        }),
        /// USB PAD Calibration
        /// offset: 0x28
        PADCAL: mmio.Mmio(packed struct(u16) {
            /// USB Pad Transp calibration
            TRANSP: u5,
            reserved6: u1 = 0,
            /// USB Pad Transn calibration
            TRANSN: u5,
            reserved12: u1 = 0,
            /// USB Pad Trim calibration
            TRIM: u3,
            padding: u1 = 0,
        }),
    },
};

/// Universal Serial Bus
pub const USB_DESCRIPTOR = extern union {
    pub const Mode = enum {
        DEVICE,
        HOST,
    };

    pub fn get_mode(self: *volatile @This()) Mode {
        {
            const value = self.CTRLA.read().MODE;
            switch (value) {
                0,
                => return .DEVICE,
                else => {},
            }
        }
        {
            const value = self.CTRLA.read().MODE;
            switch (value) {
                1,
                => return .HOST,
                else => {},
            }
        }

        unreachable;
    }

    DEVICE: extern struct {},
    HOST: extern struct {},
};
