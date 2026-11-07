//! Virtual-list window calculations for large menus and inventories.
//! Returns a half-open range [start, end); C++ still renders the rows.

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct VisibleRange {
    pub start: usize,
    pub end: usize,
}

pub fn visible_range(
    item_count: usize,
    first_visible: usize,
    visible_count: usize,
    overscan: usize,
) -> VisibleRange {
    let first = first_visible.min(item_count);
    let start = first.saturating_sub(overscan);
    let end = first
        .saturating_add(visible_count)
        .saturating_add(overscan)
        .min(item_count);
    VisibleRange { start, end: end.max(start) }
}

#[cfg(test)]
mod tests {
    use super::{VisibleRange, visible_range};

    #[test]
    fn computes_overscanned_window() {
        assert_eq!(
            visible_range(100, 20, 10, 3),
            VisibleRange { start: 17, end: 33 }
        );
    }

    #[test]
    fn handles_empty_and_overflowing_ranges() {
        assert_eq!(visible_range(0, usize::MAX, 10, 2), VisibleRange { start: 0, end: 0 });
        assert_eq!(visible_range(12, usize::MAX, 10, 2), VisibleRange { start: 10, end: 12 });
    }
}
