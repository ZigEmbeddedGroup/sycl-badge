//! ELF → UF2 for badge carts.
//!
//! The badge's loader (`src/os/loader/loader.zig`) reads a `.uf2` off the FAT12
//! drive, copies each block to its target address in cart RAM, finds the cart
//! descriptor, zeroes `.bss` and jumps to the entry point. So packing is the
//! whole of "deploy": there is no debugger in the loop and no second chance to
//! validate.
//!
//! Which is why this checks more than it strictly must. Everything the loader
//! and `executeCart` in `src/os/cart.zig` verify before handing over Core 1 —
//! the address window, the descriptor's magic and version, the `.bss` bounds,
//! the entry point — is verified here too, plus the one thing neither of them
//! checks: that the image leaves the stack its reserve. A cart that the badge
//! would reject fails at the desk instead, with a message saying which rule it
//! broke.

use std::fmt;

/// Cart RAM, from `sycl-cart/cart_ram.x`, which mirrors `src/cart/cart_ram.ld`.
/// The loader refuses blocks outside `process_ram`, and everything below this
/// inside it belongs to the IPC block.
pub const RAM_START: u32 = 0x2003_5100;
/// End of `process_ram`. `executeCart` sets MSP here before jumping in.
pub const RAM_END: u32 = 0x2008_0000;
/// How much of the top of RAM `cart_ram.x` keeps `.bss` out of, for the stack.
pub const STACK_RESERVE: u32 = 32 * 1024;

/// `CartDescriptorTable_v1` in `src/os/cart/cart_descriptor.zig`. The loader
/// scans every RAM block for the magic, one aligned word at a time, and takes
/// the first hit.
const CART_MAGIC: u32 = 0x54C1_CA41;
const CART_VERSION_V1: u32 = 0x54C1_2601;
const DESCRIPTOR_WORDS: usize = 5;

/// `platform::init` points VTOR at the start of the image, and VTOR ignores
/// the low seven bits of what it is given.
const VECTOR_TABLE_ALIGN: u32 = 128;

/// RP2354B shares the RP2350 ARM-S family (`src/os/loader/uf2.zig`).
const FAMILY_RP2350_ARM_S: u32 = 0xE48B_FF59;

const MAGIC_START0: u32 = 0x0A32_4655;
const MAGIC_START1: u32 = 0x9E5D_5157;
const MAGIC_END: u32 = 0x0AB1_6F30;
const FLAG_FAMILY_ID_PRESENT: u32 = 0x0000_2000;

/// Bytes of payload per 512-byte block. The RP2xxx convention, and what the
/// loader's flash path is sized around; its RAM path copies whatever length a
/// block declares.
const PAYLOAD: usize = 256;

#[derive(Debug)]
pub enum Error {
    NotElf,
    NotArm32,
    NoLoadableSegments,
    Truncated,
    OutsideCartRam { lo: u32, hi: u32 },
    Misaligned(u32),
    NoDescriptor,
    BadDescriptorVersion(u32),
    BadBss { start: u32, end: u32 },
    BadEntry(u32),
    NoStackRoom { top: u32 },
}

impl fmt::Display for Error {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Error::NotElf => write!(f, "not an ELF file"),
            Error::NotArm32 => write!(f, "not a 32-bit little-endian ARM ELF"),
            Error::NoLoadableSegments => write!(f, "no loadable segments with content"),
            Error::Truncated => write!(f, "ELF is truncated"),
            Error::OutsideCartRam { lo, hi } => write!(
                f,
                "image spans {lo:#010x}..{hi:#010x}, outside cart RAM \
                 {RAM_START:#010x}..{RAM_END:#010x} — check cart_ram.x"
            ),
            Error::Misaligned(base) => write!(
                f,
                "image starts at {base:#010x}; the vector table at its start needs \
                 {VECTOR_TABLE_ALIGN}-byte alignment for VTOR"
            ),
            Error::NoDescriptor => write!(
                f,
                "no cart descriptor: the loader scans for {CART_MAGIC:#010x} and \
                 would refuse this image — check the .cart_descriptor section in cart_ram.x"
            ),
            Error::BadDescriptorVersion(v) => write!(
                f,
                "cart descriptor version is {v:#010x}; the OS knows {CART_VERSION_V1:#010x}"
            ),
            Error::BadBss { start, end } => write!(
                f,
                ".bss is {start:#010x}..{end:#010x}; the loader zeroes it and needs it \
                 inside cart RAM {RAM_START:#010x}..{RAM_END:#010x}"
            ),
            Error::BadEntry(pc) => write!(
                f,
                "entry point is {pc:#010x}; the OS needs a Thumb address (low bit set) \
                 inside the image"
            ),
            Error::NoStackRoom { top } => write!(
                f,
                "the cart reaches {top:#010x}, into the {STACK_RESERVE}-byte stack reserve \
                 below {RAM_END:#010x}"
            ),
        }
    }
}

/// What the loader reads out of the image before it jumps.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Descriptor {
    /// Where the descriptor sits.
    pub addr: u32,
    pub bss_start: u32,
    pub bss_end: u32,
    /// Thumb address of `_start`, low bit set.
    pub entry: u32,
}

/// A flat image plus the address it loads at.
pub struct Image {
    pub base: u32,
    pub bytes: Vec<u8>,
    pub descriptor: Descriptor,
}

impl Image {
    pub fn end(&self) -> u32 {
        self.base + self.bytes.len() as u32
    }

    /// The highest address the cart occupies before the stack: the end of the
    /// image or of `.bss`, whichever is later.
    pub fn top(&self) -> u32 {
        self.end().max(self.descriptor.bss_end)
    }

    /// Bytes between the cart's top and the bottom of the stack reserve.
    pub fn headroom(&self) -> u32 {
        (RAM_END - STACK_RESERVE).saturating_sub(self.top())
    }
}

/// Flatten an ELF's loadable segments into one image at their load addresses,
/// then apply the loader's checks to it.
///
/// Segments are placed by *physical* address. With `cart_ram.x` that is the
/// same as the virtual address — `.data` is linked in place — but the physical
/// one is what a loader programs, so it is the right one to read on principle.
/// Gaps between segments become zero, which is what `.bss` would want anyway.
pub fn image_from_elf(elf: &[u8]) -> Result<Image, Error> {
    if elf.len() < 52 || &elf[..4] != b"\x7fELF" {
        return Err(Error::NotElf);
    }
    // 32-bit (class 1), little-endian (data 1), machine 40 = ARM.
    if elf[4] != 1 || elf[5] != 1 || read_u16(elf, 18).ok_or(Error::Truncated)? != 40 {
        return Err(Error::NotArm32);
    }

    let phoff = read_u32(elf, 28).ok_or(Error::Truncated)? as usize;
    let phentsize = read_u16(elf, 42).ok_or(Error::Truncated)? as usize;
    let phnum = read_u16(elf, 44).ok_or(Error::Truncated)? as usize;

    let mut segments: Vec<(u32, &[u8])> = Vec::new();
    for i in 0..phnum {
        let off = phoff + i * phentsize;
        if off + 32 > elf.len() {
            return Err(Error::Truncated);
        }
        const PT_LOAD: u32 = 1;
        if read_u32(elf, off).ok_or(Error::Truncated)? != PT_LOAD {
            continue;
        }
        let p_offset = read_u32(elf, off + 4).ok_or(Error::Truncated)? as usize;
        let p_paddr = read_u32(elf, off + 12).ok_or(Error::Truncated)?;
        let p_filesz = read_u32(elf, off + 16).ok_or(Error::Truncated)? as usize;

        // `.bss` occupies no file bytes; the loader zeroes it from the descriptor.
        if p_filesz == 0 {
            continue;
        }
        let end = p_offset.checked_add(p_filesz).ok_or(Error::Truncated)?;
        if end > elf.len() {
            return Err(Error::Truncated);
        }
        segments.push((p_paddr, &elf[p_offset..end]));
    }

    if segments.is_empty() {
        return Err(Error::NoLoadableSegments);
    }
    segments.sort_by_key(|(addr, _)| *addr);

    let lo = segments[0].0;
    let hi = segments
        .iter()
        .map(|(addr, data)| *addr + data.len() as u32)
        .max()
        .expect("non-empty");

    if lo < RAM_START || hi > RAM_END {
        return Err(Error::OutsideCartRam { lo, hi });
    }

    let mut bytes = vec![0u8; (hi - lo) as usize];
    for (addr, data) in segments {
        let at = (addr - lo) as usize;
        bytes[at..at + data.len()].copy_from_slice(data);
    }

    validate(lo, bytes)
}

/// Apply the checks the loader and `executeCart` apply, and the stack check
/// `cart_ram.x` applies at link time, so a cart the badge would reject — or
/// accept and then crash — never reaches it.
fn validate(base: u32, bytes: Vec<u8>) -> Result<Image, Error> {
    if !base.is_multiple_of(VECTOR_TABLE_ALIGN) {
        return Err(Error::Misaligned(base));
    }

    let descriptor = find_descriptor(base, &bytes).ok_or(Error::NoDescriptor)?;
    let version = read_u32(&bytes, (descriptor.addr - base) as usize + 4).expect("in image");
    if version != CART_VERSION_V1 {
        return Err(Error::BadDescriptorVersion(version));
    }

    let (start, end) = (descriptor.bss_start, descriptor.bss_end);
    if start < RAM_START || end > RAM_END || start > end {
        return Err(Error::BadBss { start, end });
    }

    let image_end = base + bytes.len() as u32;
    let pc = descriptor.entry;
    if pc & 1 == 0 || !(base..image_end).contains(&(pc & !1)) {
        return Err(Error::BadEntry(pc));
    }

    let image = Image {
        base,
        bytes,
        descriptor,
    };
    if image.top() + STACK_RESERVE > RAM_END {
        return Err(Error::NoStackRoom { top: image.top() });
    }
    Ok(image)
}

/// The loader's search: the first aligned word equal to the magic, with four
/// more words after it.
fn find_descriptor(base: u32, bytes: &[u8]) -> Option<Descriptor> {
    let words = bytes.len() / 4;
    (0..words.saturating_sub(DESCRIPTOR_WORDS - 1))
        .map(|w| w * 4)
        .find(|&at| read_u32(bytes, at) == Some(CART_MAGIC))
        .map(|at| Descriptor {
            addr: base + at as u32,
            bss_start: read_u32(bytes, at + 8).expect("in image"),
            bss_end: read_u32(bytes, at + 12).expect("in image"),
            entry: read_u32(bytes, at + 16).expect("in image"),
        })
}

/// Pack an image into UF2 blocks.
pub fn pack(image: &Image) -> Vec<u8> {
    let num_blocks = image.bytes.len().div_ceil(PAYLOAD) as u32;
    let mut out = Vec::with_capacity(num_blocks as usize * 512);

    for (i, chunk) in image.bytes.chunks(PAYLOAD).enumerate() {
        let mut block = [0u8; 512];
        let addr = image.base + (i * PAYLOAD) as u32;
        let header = [
            MAGIC_START0,
            MAGIC_START1,
            FLAG_FAMILY_ID_PRESENT,
            addr,
            // The exact length: the loader copies `payload_size` bytes to RAM,
            // and a padded final block would write past the image into
            // whatever follows.
            chunk.len() as u32,
            i as u32,
            num_blocks,
            FAMILY_RP2350_ARM_S,
        ];
        for (w, value) in header.iter().enumerate() {
            block[w * 4..w * 4 + 4].copy_from_slice(&value.to_le_bytes());
        }
        block[32..32 + chunk.len()].copy_from_slice(chunk);
        block[508..512].copy_from_slice(&MAGIC_END.to_le_bytes());
        out.extend_from_slice(&block);
    }
    out
}

fn read_u16(b: &[u8], at: usize) -> Option<u16> {
    Some(u16::from_le_bytes(b.get(at..at + 2)?.try_into().ok()?))
}

fn read_u32(b: &[u8], at: usize) -> Option<u32> {
    Some(u32::from_le_bytes(b.get(at..at + 4)?.try_into().ok()?))
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Where the test images put their descriptor: right after a 16-entry
    /// vector table, as `cart_ram.x` does.
    const DESCRIPTOR_AT: usize = 64;
    const ENTRY_AT: usize = 0x100;

    fn put(bytes: &mut [u8], at: usize, v: u32) {
        bytes[at..at + 4].copy_from_slice(&v.to_le_bytes());
    }

    /// A well-formed image of `len` bytes at `base`: vector table, descriptor,
    /// an entry point inside the image, and a 256-byte `.bss` right after it.
    fn image_bytes(base: u32, len: usize) -> Vec<u8> {
        assert!(len >= ENTRY_AT + 4);
        let mut bytes = vec![0u8; len];
        put(&mut bytes, 0, RAM_END);
        put(&mut bytes, 4, (base + ENTRY_AT as u32) | 1);
        put(&mut bytes, DESCRIPTOR_AT, CART_MAGIC);
        put(&mut bytes, DESCRIPTOR_AT + 4, CART_VERSION_V1);
        put(&mut bytes, DESCRIPTOR_AT + 8, base + len as u32);
        put(&mut bytes, DESCRIPTOR_AT + 12, base + len as u32 + 0x100);
        put(&mut bytes, DESCRIPTOR_AT + 16, (base + ENTRY_AT as u32) | 1);
        bytes
    }

    fn image(base: u32, len: usize) -> Image {
        validate(base, image_bytes(base, len)).expect("valid test image")
    }

    #[test]
    fn packs_whole_blocks_with_the_right_magic() {
        let uf2 = pack(&image(RAM_START, PAYLOAD * 2));
        assert_eq!(uf2.len(), 1024);
        for (i, block) in uf2.chunks(512).enumerate() {
            assert_eq!(read_u32(block, 0), Some(MAGIC_START0));
            assert_eq!(read_u32(block, 4), Some(MAGIC_START1));
            assert_eq!(read_u32(block, 508), Some(MAGIC_END));
            assert_eq!(read_u32(block, 12), Some(RAM_START + (i * PAYLOAD) as u32));
            assert_eq!(read_u32(block, 16), Some(PAYLOAD as u32));
            assert_eq!(read_u32(block, 20), Some(i as u32));
            assert_eq!(read_u32(block, 24), Some(2));
            assert_eq!(read_u32(block, 28), Some(FAMILY_RP2350_ARM_S));
        }
    }

    #[test]
    fn a_short_final_block_declares_only_its_own_bytes() {
        let mut img = image(RAM_START, 2 * PAYLOAD + 1);
        img.bytes[2 * PAYLOAD] = 0xAB;
        let uf2 = pack(&img);
        assert_eq!(uf2.len(), 1536, "a partial chunk still costs a whole block");
        let last = &uf2[1024..];
        assert_eq!(read_u32(last, 16), Some(1), "the loader copies exactly this many");
        assert_eq!(last[32], 0xAB);
        assert!(last[33..32 + PAYLOAD].iter().all(|&b| b == 0));
    }

    #[test]
    fn finds_the_descriptor_where_the_loader_would() {
        let img = image(RAM_START, 512);
        assert_eq!(img.descriptor.addr, RAM_START + DESCRIPTOR_AT as u32);
        assert_eq!(img.descriptor.bss_start, RAM_START + 512);
        assert_eq!(img.descriptor.bss_end, RAM_START + 512 + 0x100);
        assert_eq!(img.descriptor.entry, (RAM_START + ENTRY_AT as u32) | 1);
        assert_eq!(img.top(), img.descriptor.bss_end);
    }

    #[test]
    fn rejects_an_image_without_a_descriptor() {
        let mut bytes = image_bytes(RAM_START, 512);
        put(&mut bytes, DESCRIPTOR_AT, 0);
        assert!(matches!(validate(RAM_START, bytes), Err(Error::NoDescriptor)));
    }

    #[test]
    fn rejects_a_descriptor_version_the_os_does_not_know() {
        let mut bytes = image_bytes(RAM_START, 512);
        put(&mut bytes, DESCRIPTOR_AT + 4, CART_VERSION_V1 + 1);
        assert!(matches!(
            validate(RAM_START, bytes),
            Err(Error::BadDescriptorVersion(_))
        ));
    }

    #[test]
    fn rejects_an_arm_mode_entry_point() {
        let mut bytes = image_bytes(RAM_START, 512);
        // Thumb bit clear: the loader answers AddressMismatch.
        put(&mut bytes, DESCRIPTOR_AT + 16, RAM_START + ENTRY_AT as u32);
        assert!(matches!(validate(RAM_START, bytes), Err(Error::BadEntry(_))));
    }

    #[test]
    fn rejects_an_entry_point_outside_the_image() {
        let mut bytes = image_bytes(RAM_START, 512);
        put(&mut bytes, DESCRIPTOR_AT + 16, (RAM_START + 0x1000) | 1);
        assert!(matches!(validate(RAM_START, bytes), Err(Error::BadEntry(_))));
    }

    #[test]
    fn rejects_bss_outside_cart_ram() {
        let mut bytes = image_bytes(RAM_START, 512);
        // Inside process_ram, but on the IPC block: the loader would zero the
        // framebuffer.
        put(&mut bytes, DESCRIPTOR_AT + 8, 0x2002_0020);
        assert!(matches!(validate(RAM_START, bytes), Err(Error::BadBss { .. })));
    }

    #[test]
    fn rejects_a_cart_that_reaches_into_the_stack_reserve() {
        let mut bytes = image_bytes(RAM_START, 512);
        put(&mut bytes, DESCRIPTOR_AT + 12, RAM_END - STACK_RESERVE + 4);
        assert!(matches!(
            validate(RAM_START, bytes),
            Err(Error::NoStackRoom { .. })
        ));
    }

    #[test]
    fn accepts_a_cart_that_stops_exactly_at_the_stack_reserve() {
        let mut bytes = image_bytes(RAM_START, 512);
        put(&mut bytes, DESCRIPTOR_AT + 12, RAM_END - STACK_RESERVE);
        let img = validate(RAM_START, bytes).expect("exactly full is legal");
        assert_eq!(img.headroom(), 0);
    }

    #[test]
    fn rejects_an_image_that_vtor_could_not_point_at() {
        assert!(matches!(
            validate(RAM_START + 4, image_bytes(RAM_START + 4, 512)),
            Err(Error::Misaligned(_))
        ));
    }

    #[test]
    fn rejects_an_image_outside_cart_ram() {
        // The old XIP window: a cart linked against the previous memory map.
        let elf = minimal_elf(0x101C_0000, &image_bytes(0x101C_0000, 512));
        assert!(matches!(
            image_from_elf(&elf),
            Err(Error::OutsideCartRam { .. })
        ));
    }

    #[test]
    fn reads_load_segments_by_physical_address() {
        let payload = image_bytes(RAM_START, 512);
        let elf = minimal_elf(RAM_START, &payload);
        let img = image_from_elf(&elf).expect("valid");
        assert_eq!(img.base, RAM_START);
        assert_eq!(img.bytes, payload);
    }

    /// The numbers here are copies of the ones in the linker script, which is
    /// the file the cart is actually laid out by. Keep them in step.
    #[test]
    fn constants_match_the_linker_script() {
        let script = include_str!("../../sycl-cart/cart_ram.x");
        let field = |key: &str| -> u32 {
            let at = script.find(key).unwrap_or_else(|| panic!("{key} in cart_ram.x"));
            let rest = &script[at + key.len()..];
            let hex = rest.trim_start().trim_start_matches("0x");
            let end = hex.find(|c: char| !c.is_ascii_hexdigit()).unwrap_or(hex.len());
            u32::from_str_radix(&hex[..end], 16).expect("hex")
        };
        assert_eq!(field("ORIGIN ="), RAM_START);
        assert_eq!(field("ORIGIN =") + field("LENGTH ="), RAM_END);
        assert_eq!(field("LONG(0x"), CART_MAGIC);
        assert!(script.contains(&format!("LONG({CART_VERSION_V1:#010X})")));
        assert!(script.contains("__stack_size__ = 32K"));
        assert_eq!(STACK_RESERVE, 32 * 1024);
    }

    /// One PT_LOAD segment at `paddr`, enough of an ELF32 header to parse.
    fn minimal_elf(paddr: u32, data: &[u8]) -> Vec<u8> {
        const EHDR: usize = 52;
        const PHDR: usize = 32;
        let mut elf = vec![0u8; EHDR + PHDR];
        elf[..4].copy_from_slice(b"\x7fELF");
        elf[4] = 1; // 32-bit
        elf[5] = 1; // little-endian
        elf[18..20].copy_from_slice(&40u16.to_le_bytes()); // EM_ARM
        elf[28..32].copy_from_slice(&(EHDR as u32).to_le_bytes()); // e_phoff
        elf[42..44].copy_from_slice(&(PHDR as u16).to_le_bytes()); // e_phentsize
        elf[44..46].copy_from_slice(&1u16.to_le_bytes()); // e_phnum

        let ph = EHDR;
        elf[ph..ph + 4].copy_from_slice(&1u32.to_le_bytes()); // PT_LOAD
        elf[ph + 4..ph + 8].copy_from_slice(&((EHDR + PHDR) as u32).to_le_bytes()); // p_offset
        elf[ph + 8..ph + 12].copy_from_slice(&paddr.to_le_bytes()); // p_vaddr
        elf[ph + 12..ph + 16].copy_from_slice(&paddr.to_le_bytes()); // p_paddr
        elf[ph + 16..ph + 20].copy_from_slice(&(data.len() as u32).to_le_bytes()); // p_filesz
        elf[ph + 20..ph + 24].copy_from_slice(&(data.len() as u32).to_le_bytes()); // p_memsz
        elf.extend_from_slice(data);
        elf
    }
}
