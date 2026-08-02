//! A small deterministic PRNG.
//!
//! Not the hardware entropy source: the badge's `rand()` samples the ring
//! oscillator 32 times per `u32`, which is far too slow to call per frame. Seed
//! this once and pull from it instead.

use crate::platform;

/// xorshift32. Two words of state, a handful of instructions per draw.
#[derive(Copy, Clone)]
pub struct Rng {
    state: u32,
}

impl Rng {
    /// Fixed seed — reproducible, which is what you want for tests and for
    /// debugging a level that misbehaves.
    pub const fn seeded(seed: u32) -> Rng {
        // xorshift dies at zero.
        Rng {
            state: if seed == 0 { 0x9E37_79B9 } else { seed },
        }
    }

    /// Seed from the platform entropy source (ring oscillator on the badge,
    /// `Math.random` in the simulator).
    pub fn from_entropy() -> Rng {
        Rng::seeded(platform::entropy())
    }

    #[inline]
    pub fn next_u32(&mut self) -> u32 {
        let mut x = self.state;
        x ^= x << 13;
        x ^= x >> 17;
        x ^= x << 5;
        self.state = x;
        x
    }

    /// Uniform-ish in `0..n`. Returns 0 when `n == 0`.
    #[inline]
    pub fn below(&mut self, n: u32) -> u32 {
        if n == 0 {
            return 0;
        }
        // Multiply-shift: one multiply, no division, bias negligible at game scale.
        ((self.next_u32() as u64 * n as u64) >> 32) as u32
    }

    /// Uniform-ish in `lo..hi`. Returns `lo` if the range is empty.
    #[inline]
    pub fn range(&mut self, lo: i32, hi: i32) -> i32 {
        if hi <= lo {
            return lo;
        }
        lo + self.below((hi - lo) as u32) as i32
    }

    #[inline]
    pub fn bool(&mut self) -> bool {
        self.next_u32() & 0x8000_0000 != 0
    }

    /// In `0.0..1.0`.
    #[inline]
    pub fn unit(&mut self) -> f32 {
        (self.next_u32() >> 8) as f32 / (1u32 << 24) as f32
    }
}

#[cfg(test)]
mod tests {
    use super::Rng;

    #[test]
    fn zero_seed_still_produces_values() {
        let mut r = Rng::seeded(0);
        assert_ne!(r.next_u32(), 0);
        assert_ne!(r.next_u32(), 0);
    }

    #[test]
    fn below_respects_the_bound() {
        let mut r = Rng::seeded(42);
        for _ in 0..1000 {
            assert!(r.below(7) < 7);
        }
        assert_eq!(r.below(0), 0);
    }

    #[test]
    fn range_handles_empty_and_negative() {
        let mut r = Rng::seeded(7);
        assert_eq!(r.range(5, 5), 5);
        assert_eq!(r.range(5, 1), 5);
        for _ in 0..1000 {
            let v = r.range(-10, 10);
            assert!((-10..10).contains(&v));
        }
    }

    #[test]
    fn unit_stays_in_range() {
        let mut r = Rng::seeded(1);
        for _ in 0..1000 {
            let v = r.unit();
            assert!((0.0..1.0).contains(&v));
        }
    }

    #[test]
    fn same_seed_same_sequence() {
        let mut a = Rng::seeded(99);
        let mut b = Rng::seeded(99);
        for _ in 0..10 {
            assert_eq!(a.next_u32(), b.next_u32());
        }
    }
}
