//! Persistent storage.
//!
//! **The badge cannot do this yet.** `read_flash`/`write_flash_page` in
//! `src/os/cart/api.zig` are no-op stubs on v2 — no cart save-data flash region
//! has been carved out. The simulator does implement them, against a 4 MiB
//! buffer.
//!
//! The API exists now so that adding real storage later is additive rather than
//! a breaking change. Write code that tolerates [`Save::read`] returning 0.

use crate::platform;

/// Bytes per flash page. Writes are page-granular.
pub const PAGE_SIZE: usize = 256;

/// Handle to the cart's save area. Reached through [`crate::Ctx`].
pub struct Save {
    _private: (),
}

impl Save {
    pub(crate) const NEW: Save = Save { _private: () };

    /// Whether writes actually persist on this platform.
    ///
    /// `false` on the badge today. Check it before showing the player a
    /// "saved!" message.
    pub const PERSISTS: bool = cfg!(target_arch = "wasm32");

    /// Read into `dst`, returning how many bytes were actually filled. Returns 0
    /// when storage is unavailable.
    #[inline]
    pub fn read(&self, offset: u32, dst: &mut [u8]) -> usize {
        platform::save_read(offset, dst)
    }

    /// Write one full page. Silently does nothing when storage is unavailable.
    #[inline]
    pub fn write_page(&mut self, page: u16, src: &[u8; PAGE_SIZE]) {
        platform::save_write_page(page, src);
    }

    /// Convenience for a single little-endian `u32` at page 0 — enough for a
    /// high score.
    pub fn read_u32(&self, offset: u32) -> Option<u32> {
        let mut buf = [0u8; 4];
        if self.read(offset, &mut buf) == 4 {
            Some(u32::from_le_bytes(buf))
        } else {
            None
        }
    }
}
