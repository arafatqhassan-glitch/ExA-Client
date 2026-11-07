//! Defensive, allocation-free helpers shared by UI and loading code.

/// Clamp a scroll offset to a valid range. Non-finite values become zero.
pub fn clamp_scroll_offset(offset: f32, maximum: f32) -> f32 {
    if !offset.is_finite() || !maximum.is_finite() || maximum <= 0.0 {
        return 0.0;
    }
    offset.clamp(0.0, maximum)
}

#[cfg(test)]
mod tests {
    use super::clamp_scroll_offset;

    #[test]
    fn clamps_scroll_and_rejects_nan() {
        assert_eq!(clamp_scroll_offset(-4.0, 20.0), 0.0);
        assert_eq!(clamp_scroll_offset(25.0, 20.0), 20.0);
        assert_eq!(clamp_scroll_offset(8.0, 20.0), 8.0);
        assert_eq!(clamp_scroll_offset(f32::NAN, 20.0), 0.0);
    }
}
