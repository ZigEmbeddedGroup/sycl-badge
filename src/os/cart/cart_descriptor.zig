// Carts begin with a Cart Descriptor Table, which tells the OS about
// the cart contents. All descriptor tables of all versions begin with
// CART_MAGIC, followed by the version number. This allows the OS to
// ensure that it is reading a valid version table before jumping to
// its entry point. The OS maintains limited backwards compatibility
// for older versions, which are maintained in this file.
pub const CART_MAGIC = 0x54C1_CA41;

pub const CART_VERSION_V1: u32 = 0x54C126_01;
pub const CartDescriptorTable_v1 = extern struct {
    magic: u32 = CART_MAGIC,
    version: u32 = CART_VERSION_V1,
    bss_start: *u8,
    bss_end: *u8,
    entry_point: *const fn() callconv(.c) void,
};

pub const CART_VERSION_CURRENT = CART_VERSION_V1;
pub const CartDescriptorTable = CartDescriptorTable_v1;
