const microzig = @import("microzig");
const mmio = microzig.mmio;

const types = @import("../../types.zig");

pub const NVIC = extern struct {
    /// Interrupt Set Enable Register
    /// offset: 0x00
    ISER: [5]mmio.Mmio(packed struct(u32) {
        /// Interrupt set enable bits
        SETENA: u32,
    }),
    /// offset: 0x14
    reserved20: [108]u8,
    /// Interrupt Clear Enable Register
    /// offset: 0x80
    ICER: [5]mmio.Mmio(packed struct(u32) {
        /// Interrupt clear-enable bits
        CLRENA: u32,
    }),
    /// offset: 0x94
    reserved148: [108]u8,
    /// Interrupt Set Pending Register
    /// offset: 0x100
    ISPR: [5]mmio.Mmio(packed struct(u32) {
        /// Interrupt set-pending bits
        SETPEND: u32,
    }),
    /// offset: 0x114
    reserved276: [108]u8,
    /// Interrupt Clear Pending Register
    /// offset: 0x180
    ICPR: [5]mmio.Mmio(packed struct(u32) {
        /// Interrupt clear-pending bits
        CLRPEND: u32,
    }),
    /// offset: 0x194
    reserved404: [108]u8,
    /// Interrupt Active Bit Register
    /// offset: 0x200
    IABR: [5]mmio.Mmio(packed struct(u32) {
        /// Interrupt active bits
        ACTIVE: u32,
    }),
    /// offset: 0x214
    reserved532: [236]u8,
    /// Interrupt Priority Register n
    /// offset: 0x300
    IP: [35]mmio.Mmio(packed struct(u8) {
        /// Priority of interrupt n
        PRI0: u3,
        padding: u5 = 0,
    }),
    /// offset: 0x323
    reserved803: [2781]u8,
    /// Software Trigger Interrupt Register
    /// offset: 0xe00
    STIR: mmio.Mmio(packed struct(u32) {
        /// Interrupt ID to trigger
        INTID: u9,
        padding: u23 = 0,
    }),
};
