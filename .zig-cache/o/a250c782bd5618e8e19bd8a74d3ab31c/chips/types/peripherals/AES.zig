const microzig = @import("microzig");
const mmio = microzig.mmio;

const types = @import("../../types.zig");

pub const AES = extern struct {
    pub const AES_CTRLA__AESMODE = enum(u3) {
        /// Electronic code book mode
        ECB = 0x0,
        /// Cipher block chaining mode
        CBC = 0x1,
        /// Output feedback mode
        OFB = 0x2,
        /// Cipher feedback mode
        CFB = 0x3,
        /// Counter mode
        COUNTER = 0x4,
        /// CCM mode
        CCM = 0x5,
        /// Galois counter mode
        GCM = 0x6,
        _,
    };

    pub const AES_CTRLA__CFBS = enum(u3) {
        /// 128-bit Input data block for Encryption/Decryption in Cipher Feedback mode
        @"128BIT" = 0x0,
        /// 64-bit Input data block for Encryption/Decryption in Cipher Feedback mode
        @"64BIT" = 0x1,
        /// 32-bit Input data block for Encryption/Decryption in Cipher Feedback mode
        @"32BIT" = 0x2,
        /// 16-bit Input data block for Encryption/Decryption in Cipher Feedback mode
        @"16BIT" = 0x3,
        /// 8-bit Input data block for Encryption/Decryption in Cipher Feedback mode
        @"8BIT" = 0x4,
        _,
    };

    pub const AES_CTRLA__CIPHER = enum(u1) {
        /// Decryption
        DEC = 0x0,
        /// Encryption
        ENC = 0x1,
    };

    pub const AES_CTRLA__KEYGEN = enum(u1) {
        /// No effect
        NONE = 0x0,
        /// Start Computation of the last NK words of the expanded key
        LAST = 0x1,
    };

    pub const AES_CTRLA__KEYSIZE = enum(u2) {
        /// 128-bit Key for Encryption / Decryption
        @"128BIT" = 0x0,
        /// 192-bit Key for Encryption / Decryption
        @"192BIT" = 0x1,
        /// 256-bit Key for Encryption / Decryption
        @"256BIT" = 0x2,
        _,
    };

    pub const AES_CTRLA__LOD = enum(u1) {
        /// No effect
        NONE = 0x0,
        /// Start encryption in Last Output Data mode
        LAST = 0x1,
    };

    pub const AES_CTRLA__STARTMODE = enum(u1) {
        /// Start Encryption / Decryption in Manual mode
        MANUAL = 0x0,
        /// Start Encryption / Decryption in Auto mode
        AUTO = 0x1,
    };

    pub const AES_CTRLA__XORKEY = enum(u1) {
        /// No effect
        NONE = 0x0,
        /// The user keyword gets XORed with the previous keyword register content.
        XOR = 0x1,
    };

    /// Control A
    /// offset: 0x00
    CTRLA: mmio.Mmio(packed struct(u32) {
        /// Software Reset
        SWRST: u1,
        /// Enable
        ENABLE: u1,
        /// AES Modes of operation
        AESMODE: AES_CTRLA__AESMODE,
        /// Cipher Feedback Block Size
        CFBS: AES_CTRLA__CFBS,
        /// Encryption Key Size
        KEYSIZE: AES_CTRLA__KEYSIZE,
        /// Cipher Mode
        CIPHER: AES_CTRLA__CIPHER,
        /// Start Mode Select
        STARTMODE: AES_CTRLA__STARTMODE,
        /// Last Output Data Mode
        LOD: AES_CTRLA__LOD,
        /// Last Key Generation
        KEYGEN: AES_CTRLA__KEYGEN,
        /// XOR Key Operation
        XORKEY: AES_CTRLA__XORKEY,
        reserved16: u1 = 0,
        /// Counter Measure Type
        CTYPE: u4,
        padding: u12 = 0,
    }),
    /// Control B
    /// offset: 0x04
    CTRLB: mmio.Mmio(packed struct(u8) {
        /// Start Encryption/Decryption
        START: u1,
        /// New message
        NEWMSG: u1,
        /// End of message
        EOM: u1,
        /// GF Multiplication
        GFMUL: u1,
        padding: u4 = 0,
    }),
    /// Interrupt Enable Clear
    /// offset: 0x05
    INTENCLR: mmio.Mmio(packed struct(u8) {
        /// Encryption Complete Interrupt Enable
        ENCCMP: u1,
        /// GF Multiplication Complete Interrupt Enable
        GFMCMP: u1,
        padding: u6 = 0,
    }),
    /// Interrupt Enable Set
    /// offset: 0x06
    INTENSET: mmio.Mmio(packed struct(u8) {
        /// Encryption Complete Interrupt Enable
        ENCCMP: u1,
        /// GF Multiplication Complete Interrupt Enable
        GFMCMP: u1,
        padding: u6 = 0,
    }),
    /// Interrupt Flag Status
    /// offset: 0x07
    INTFLAG: mmio.Mmio(packed struct(u8) {
        /// Encryption Complete
        ENCCMP: u1,
        /// GF Multiplication Complete
        GFMCMP: u1,
        padding: u6 = 0,
    }),
    /// Data buffer pointer
    /// offset: 0x08
    DATABUFPTR: mmio.Mmio(packed struct(u8) {
        /// Input Data Pointer
        INDATAPTR: u2,
        padding: u6 = 0,
    }),
    /// Debug control
    /// offset: 0x09
    DBGCTRL: mmio.Mmio(packed struct(u8) {
        /// Debug Run
        DBGRUN: u1,
        padding: u7 = 0,
    }),
    /// offset: 0x0a
    reserved10: [2]u8,
    /// Keyword n
    /// offset: 0x0c
    KEYWORD: [8]u32,
    /// offset: 0x2c
    reserved44: [12]u8,
    /// Indata
    /// offset: 0x38
    INDATA: u32,
    /// Initialisation Vector n
    /// offset: 0x3c
    INTVECTV: [4]u32,
    /// offset: 0x4c
    reserved76: [16]u8,
    /// Hash key n
    /// offset: 0x5c
    HASHKEY: [4]u32,
    /// Galois Hash n
    /// offset: 0x6c
    GHASH: [4]u32,
    /// offset: 0x7c
    reserved124: [4]u8,
    /// Cipher Length
    /// offset: 0x80
    CIPLEN: u32,
    /// Random Seed
    /// offset: 0x84
    RANDSEED: u32,
};
