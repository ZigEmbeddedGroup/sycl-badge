//! ELF → UF2 for badge carts.
//!
//! The badge's loader (`src/os/loader/loader.zig`) reads a `.uf2` off the FAT12
//! drive, programs the payload into the cart_xip flash region and jumps to the
//! reset vector. So packing is the whole of "deploy": there is no debugger in
//! the loop and no second chance to validate.
//!
//! Which is why this checks more than it strictly must. Everything `executeCart`
//! in `src/os/cart.zig` verifies before handing over Core 1 — the stack pointer,
//! the reset vector, the address range — is verified here too. A cart that would
//! be rejected by the badge fails at the desk instead, with a message saying
//! which rule it broke.

use std::fmt;

/// Cart flash window, from `src/cart/cart_xip.ld`. The loader refuses anything
/// outside it.
pub const CART_XIP_START: u32 = 0x101C_0000;
pub const CART_XIP_END: u32 = 0x1020_0000;

/// Widest stack pointer `executeCart` accepts, and the bottom of cart RAM.
const SP_MIN: u32 = 0x2002_A100;
const SP_MAX: u32 = 0x2008_0000;

/// RP2354B shares the RP2350 ARM-S family (`src/os/loader/uf2.zig`).
const FAMILY_RP2350_ARM_S: u32 = 0xE48B_FF59;

const MAGIC_START0: u32 = 0x0A32_4655;
const MAGIC_START1: u32 = 0x9E5D_5157;
const MAGIC_END: u32 = 0x0AB1_6F30;
const FLAG_FAMILY_ID_PRESENT: u32 = 0x0000_2000;

/// Bytes of payload per 512-byte block. The loader assumes this ratio when it
/// sizes its staging buffer, so do not raise it.
const PAYLOAD: usize = 256;

/// The loader stages the whole `.uf2` in a 320 KiB buffer
/// (`cart_buffer` in `src/os/loader/loader.zig`), which at 256 payload bytes per
/// 512-byte block caps the image at half that.
const MAX_IMAGE: usize = 160 * 1024;

#[derive(Debug)]
pub enum Error {
    NotElf,
    NotArm32,
    NoLoadableSegments,
    Truncated,
    OutsideCartWindow { lo: u32, hi: u32 },
    TooBig(usize),
    BadStackPointer(u32),
    BadResetVector(u32),
}

impl fmt::Display for Error {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Error::NotElf => write!(f, "not an ELF file"),
            Error::NotArm32 => write!(f, "not a 32-bit little-endian ARM ELF"),
            Error::NoLoadableSegments => write!(f, "no loadable segments with content"),
            Error::Truncated => write!(f, "ELF is truncated"),
            Error::OutsideCartWindow { lo, hi } => write!(
                f,
                "image spans {lo:#010x}..{hi:#010x}, outside the cart window \
                 {CART_XIP_START:#010x}..{CART_XIP_END:#010x} — check memory.x"
            ),
            Error::TooBig(n) => write!(
                f,
                "image is {n} bytes; the loader caps a cart at {MAX_IMAGE} bytes"
            ),
            Error::BadStackPointer(sp) => write!(
                f,
                "vector table word 0 is {sp:#010x}; the OS needs an 8-byte-aligned \
                 stack pointer in {SP_MIN:#010x}..={SP_MAX:#010x}"
            ),
            Error::BadResetVector(pc) => write!(
                f,
                "vector table word 1 is {pc:#010x}; the OS needs a Thumb address \
                 (low bit set) inside the cart window"
            ),
        }
    }
}

/// A flat image plus the address it loads at.
pub struct Image {
    pub base: u32,
    pub bytes: Vec<u8>,
}

impl Image {
    pub fn initial_sp(&self) -> u32 {
        read_u32(&self.bytes, 0).unwrap_or(0)
    }

    pub fn reset_vector(&self) -> u32 {
        read_u32(&self.bytes, 4).unwrap_or(0)
    }
}

/// Flatten an ELF's loadable segments into one image at their load addresses.
///
/// Segments are placed by *physical* address, not virtual: `.data` is stored in
/// flash and copied to RAM by the reset handler, and it is the flash copy that
/// has to be programmed. Gaps between segments become `0xFF`, which is what
/// erased flash reads as anyway.
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

        // `.bss` and friends occupy no file bytes and nothing needs programming.
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

    if lo < CART_XIP_START || hi > CART_XIP_END {
        return Err(Error::OutsideCartWindow { lo, hi });
    }
    let len = (hi - lo) as usize;
    if len > MAX_IMAGE {
        return Err(Error::TooBig(len));
    }

    let mut bytes = vec![0xFF; len];
    for (addr, data) in segments {
        let at = (addr - lo) as usize;
        bytes[at..at + data.len()].copy_from_slice(data);
    }

    let image = Image { base: lo, bytes };
    validate_vector_table(&image)?;
    Ok(image)
}

/// Apply the checks `executeCart` in `src/os/cart.zig` applies, so a cart that
/// the badge would reject never reaches it.
fn validate_vector_table(image: &Image) -> Result<(), Error> {
    let sp = image.initial_sp();
    if sp & 0x7 != 0 || !(SP_MIN..=SP_MAX).contains(&sp) {
        return Err(Error::BadStackPointer(sp));
    }
    let pc = image.reset_vector();
    let entry = pc & !1;
    if pc & 1 == 0 || !(CART_XIP_START..CART_XIP_END).contains(&entry) {
        return Err(Error::BadResetVector(pc));
    }
    Ok(())
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
            // Always a full payload field: the loader reads `payload_size`
            // bytes, and a short final chunk is padded with erased-flash 0xFF.
            PAYLOAD as u32,
            i as u32,
            num_blocks,
            FAMILY_RP2350_ARM_S,
        ];
        for (w, value) in header.iter().enumerate() {
            block[w * 4..w * 4 + 4].copy_from_slice(&value.to_le_bytes());
        }
        block[32..32 + PAYLOAD].fill(0xFF);
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

    fn image(base: u32, len: usize) -> Image {
        let mut bytes = vec![0u8; len];
        bytes[0..4].copy_from_slice(&SP_MAX.to_le_bytes());
        bytes[4..8].copy_from_slice(&(CART_XIP_START | 1).to_le_bytes());
        Image { base, bytes }
    }

    #[test]
    fn packs_whole_blocks_with_the_right_magic() {
        let uf2 = pack(&image(CART_XIP_START, PAYLOAD * 2));
        assert_eq!(uf2.len(), 1024);
        for (i, block) in uf2.chunks(512).enumerate() {
            assert_eq!(read_u32(block, 0), Some(MAGIC_START0));
            assert_eq!(read_u32(block, 4), Some(MAGIC_START1));
            assert_eq!(read_u32(block, 508), Some(MAGIC_END));
            assert_eq!(
                read_u32(block, 12),
                Some(CART_XIP_START + (i * PAYLOAD) as u32)
            );
            assert_eq!(read_u32(block, 20), Some(i as u32));
            assert_eq!(read_u32(block, 24), Some(2));
            assert_eq!(read_u32(block, 28), Some(FAMILY_RP2350_ARM_S));
        }
    }

    #[test]
    fn pads_a_short_final_block_with_erased_flash() {
        let uf2 = pack(&image(CART_XIP_START, PAYLOAD + 1));
        assert_eq!(uf2.len(), 1024, "a partial chunk still costs a whole block");
        let last = &uf2[512..];
        assert_eq!(read_u32(last, 16), Some(PAYLOAD as u32));
        assert_eq!(last[32], 0);
        assert!(last[33..32 + PAYLOAD].iter().all(|&b| b == 0xFF));
    }

    #[test]
    fn rejects_a_stack_pointer_the_os_would_refuse() {
        let mut img = image(CART_XIP_START, 64);
        img.bytes[0..4].copy_from_slice(&0x2000_0000u32.to_le_bytes());
        assert!(matches!(
            validate_vector_table(&img),
            Err(Error::BadStackPointer(_))
        ));
    }

    #[test]
    fn rejects_an_arm_mode_reset_vector() {
        let mut img = image(CART_XIP_START, 64);
        // Thumb bit clear: `executeCart` sends CART_CRASHED for this.
        img.bytes[4..8].copy_from_slice(&CART_XIP_START.to_le_bytes());
        assert!(matches!(
            validate_vector_table(&img),
            Err(Error::BadResetVector(_))
        ));
    }

    #[test]
    fn accepts_the_top_of_ram_as_a_stack_pointer() {
        // `executeCart` rejects `sp > 0x20080000`, so the exact top is legal and
        // is what cortex-m-rt puts there by default.
        assert!(validate_vector_table(&image(CART_XIP_START, 64)).is_ok());
    }

    #[test]
    fn rejects_an_image_outside_the_cart_window() {
        let elf = minimal_elf(0x1000_0000, &[0u8; 8]);
        assert!(matches!(
            image_from_elf(&elf),
            Err(Error::OutsideCartWindow { .. })
        ));
    }

    #[test]
    fn reads_load_segments_by_physical_address() {
        let mut payload = vec![0u8; 16];
        payload[0..4].copy_from_slice(&SP_MAX.to_le_bytes());
        payload[4..8].copy_from_slice(&(CART_XIP_START | 1).to_le_bytes());
        let elf = minimal_elf(CART_XIP_START, &payload);
        let img = image_from_elf(&elf).expect("valid");
        assert_eq!(img.base, CART_XIP_START);
        assert_eq!(img.bytes, payload);
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
