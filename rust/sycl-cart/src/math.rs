//! Float maths that `core` does not provide.
//!
//! `core` gives you `abs`, `signum`, `min`, `max` and `clamp` on `f32`, but
//! everything transcendental lives in `std` (really in libm), which a cart cannot
//! link. These are small hand-rolled replacements for the handful of operations
//! small games actually reach for.
//!
//! They trade accuracy for size and speed, and the error is documented per
//! function and pinned by tests. That is the right trade for game feel — a
//! bobbing sprite or a distance check does not care about the last few bits — but
//! if you need real precision, add [`libm`] to your cart and call that instead.
//!
//! [`libm`]: https://docs.rs/libm

use core::f32::consts::{PI, TAU};

/// Fold an angle into `0.0..TAU`.
///
/// `core` has no `rem_euclid` for floats, and `%` keeps the sign of the operand.
#[inline]
pub fn wrap_angle(radians: f32) -> f32 {
    let t = radians % TAU;
    if t < 0.0 {
        t + TAU
    } else {
        t
    }
}

/// Positive remainder, for wrapping positions and animation phases.
///
/// Returns 0 for a non-positive `period` rather than dividing by zero.
#[inline]
pub fn wrap(x: f32, period: f32) -> f32 {
    if period <= 0.0 {
        return 0.0;
    }
    let t = x % period;
    if t < 0.0 {
        t + period
    } else {
        t
    }
}

/// Sine, via the Bhaskara approximation.
///
/// Maximum absolute error about 1.8e-3, which is under half a pixel of travel
/// for any amplitude a 160x128 screen can show.
pub fn sin(radians: f32) -> f32 {
    let t = wrap_angle(radians);
    // The approximation is defined on 0..PI; the second half is its mirror.
    let (t, sign) = if t > PI { (t - PI, -1.0) } else { (t, 1.0) };
    let numerator = 16.0 * t * (PI - t);
    sign * numerator / (5.0 * PI * PI - 4.0 * t * (PI - t))
}

/// Cosine. Same accuracy as [`sin`].
#[inline]
pub fn cos(radians: f32) -> f32 {
    sin(radians + PI / 2.0)
}

/// Square root, by halving the exponent and then refining with Newton's method.
///
/// Relative error under 1e-6 for normal positive inputs. Negative inputs and NaN
/// return 0 rather than NaN, so a stray negative cannot poison a whole frame of
/// physics.
pub fn sqrt(x: f32) -> f32 {
    if x.is_nan() || x <= 0.0 {
        // Negatives and NaN clamp to zero rather than propagating.
        return 0.0;
    }
    if x.is_infinite() {
        // Newton would not converge, and the answer is already known.
        return f32::INFINITY;
    }
    // For x = m * 2^e, sqrt(x) = sqrt(m) * 2^(e/2). Adding the exponent bias
    // before the shift keeps the biased exponent correct afterwards.
    let mut y = f32::from_bits((x.to_bits() + (127 << 23)) >> 1);
    // Three Newton steps take the initial ~3% guess below 1e-6.
    y = 0.5 * (y + x / y);
    y = 0.5 * (y + x / y);
    y = 0.5 * (y + x / y);
    y
}

/// Length of the vector `(x, y)`. Accuracy follows [`sqrt`].
#[inline]
pub fn hypot(x: f32, y: f32) -> f32 {
    sqrt(x * x + y * y)
}

/// Distance between two points. Accuracy follows [`sqrt`].
///
/// For "is this closer than that" tests, compare squared distances instead and
/// skip the square root entirely.
#[inline]
pub fn dist(x0: f32, y0: f32, x1: f32, y1: f32) -> f32 {
    hypot(x1 - x0, y1 - y0)
}

/// Largest integer not greater than `x`. Exact for `|x| < 2^31`.
#[inline]
pub fn floor(x: f32) -> f32 {
    let t = x as i32 as f32;
    if x < t {
        t - 1.0
    } else {
        t
    }
}

/// Smallest integer not less than `x`. Exact for `|x| < 2^31`.
#[inline]
pub fn ceil(x: f32) -> f32 {
    let t = x as i32 as f32;
    if x > t {
        t + 1.0
    } else {
        t
    }
}

/// Truncate toward zero. Exact for `|x| < 2^31`.
#[inline]
pub fn trunc(x: f32) -> f32 {
    x as i32 as f32
}

/// Round half away from zero. Exact for `|x| < 2^31`.
#[inline]
pub fn round(x: f32) -> f32 {
    if x < 0.0 {
        -floor(-x + 0.5)
    } else {
        floor(x + 0.5)
    }
}

/// Linear interpolation. `t` is not clamped, so this extrapolates outside
/// `0.0..=1.0`.
#[inline]
pub fn lerp(a: f32, b: f32, t: f32) -> f32 {
    a + (b - a) * t
}

/// Move `current` toward `target` by at most `max_step`. Handy for easing a
/// camera or a velocity without overshoot.
#[inline]
pub fn approach(current: f32, target: f32, max_step: f32) -> f32 {
    let delta = target - current;
    if delta.abs() <= max_step {
        target
    } else {
        current + max_step * delta.signum()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Error bounds are asserted against `std` so they cannot silently regress.
    #[test]
    fn sin_is_within_its_documented_error() {
        let mut worst = 0.0f32;
        let mut at = 0.0f32;
        // Several turns in both directions, to exercise the wrapping too.
        let mut x = -20.0f32;
        while x < 20.0 {
            let err = (sin(x) - x.sin()).abs();
            if err > worst {
                worst = err;
                at = x;
            }
            x += 0.001;
        }
        assert!(worst < 1.8e-3, "max sin error {worst} at {at}");
    }

    #[test]
    fn cos_is_within_its_documented_error() {
        let mut worst = 0.0f32;
        let mut x = -20.0f32;
        while x < 20.0 {
            worst = worst.max((cos(x) - x.cos()).abs());
            x += 0.001;
        }
        assert!(worst < 1.8e-3, "max cos error {worst}");
    }

    #[test]
    fn sin_hits_the_cardinal_points() {
        assert!(sin(0.0).abs() < 1e-3);
        assert!((sin(PI / 2.0) - 1.0).abs() < 2e-3);
        assert!(sin(PI).abs() < 1e-3);
        assert!((sin(3.0 * PI / 2.0) + 1.0).abs() < 2e-3);
    }

    #[test]
    fn sqrt_is_within_its_documented_error() {
        let mut worst = 0.0f32;
        let mut at = 0.0f32;
        for &x in &[
            1e-6, 1e-3, 0.25, 0.5, 1.0, 2.0, 3.0, 9.0, 10.0, 100.0, 12345.0, 1e6, 1e12, 3.4e38,
        ] {
            let rel = ((sqrt(x) - x.sqrt()) / x.sqrt()).abs();
            if rel > worst {
                worst = rel;
                at = x;
            }
        }
        // Also sweep a dense range, where games actually live.
        let mut x = 0.01f32;
        while x < 500.0 {
            let rel = ((sqrt(x) - x.sqrt()) / x.sqrt()).abs();
            worst = worst.max(rel);
            x += 0.01;
        }
        assert!(worst < 1e-6, "max relative sqrt error {worst} at {at}");
    }

    #[test]
    fn sqrt_handles_the_degenerate_inputs() {
        assert_eq!(sqrt(0.0), 0.0);
        assert_eq!(sqrt(-1.0), 0.0, "negatives clamp rather than returning NaN");
        assert_eq!(sqrt(f32::NAN), 0.0);
        assert_eq!(sqrt(f32::NEG_INFINITY), 0.0);
        assert_eq!(sqrt(f32::INFINITY), f32::INFINITY);
    }

    #[test]
    fn hypot_and_dist_agree_with_std() {
        assert!((hypot(3.0, 4.0) - 5.0).abs() < 1e-4);
        assert!((dist(1.0, 1.0, 4.0, 5.0) - 5.0).abs() < 1e-4);
    }

    #[test]
    fn rounding_matches_std() {
        for &x in &[
            -2.5, -1.7, -1.0, -0.5, -0.2, 0.0, 0.2, 0.5, 1.0, 1.7, 2.5, 99.999,
        ] {
            assert_eq!(floor(x), x.floor(), "floor({x})");
            assert_eq!(ceil(x), x.ceil(), "ceil({x})");
            assert_eq!(trunc(x), x.trunc(), "trunc({x})");
            assert_eq!(round(x), x.round(), "round({x})");
        }
    }

    #[test]
    fn wrap_keeps_results_positive() {
        assert_eq!(wrap(7.0, 5.0), 2.0);
        assert_eq!(wrap(-1.0, 5.0), 4.0);
        assert_eq!(wrap(-6.0, 5.0), 4.0);
        assert_eq!(wrap(3.0, 0.0), 0.0, "no division by zero");
        let a = wrap_angle(-PI / 2.0);
        assert!((a - (TAU - PI / 2.0)).abs() < 1e-5);
    }

    #[test]
    fn lerp_and_approach() {
        assert_eq!(lerp(10.0, 20.0, 0.5), 15.0);
        assert_eq!(lerp(10.0, 20.0, 2.0), 30.0, "extrapolates");
        assert_eq!(approach(0.0, 10.0, 3.0), 3.0);
        assert_eq!(approach(0.0, 2.0, 3.0), 2.0, "never overshoots");
        assert_eq!(approach(0.0, -10.0, 3.0), -3.0);
    }
}
