//! C ABI exposed to the existing C++ engine.
//! Caller-owned pointers must remain valid for the duration of each call.

use core::ffi::{c_char, c_int};
use core::slice;
use core::str;

use crate::loading::LoadingProgress;
use crate::performance::clamp_scroll_offset;
use crate::ui::scrolling::visible_range;

static ENGINE_NAME: &[u8] = b"ExA Client\\0";
static ENGINE_VERSION: &[u8] = b"1.5.1\\0";

#[unsafe(no_mangle)]
pub extern "C" fn exa_engine_name() -> *const c_char {
    ENGINE_NAME.as_ptr().cast()
}

#[unsafe(no_mangle)]
pub extern "C" fn exa_engine_version() -> *const c_char {
    ENGINE_VERSION.as_ptr().cast()
}

/// Compute the visible half-open row range. Returns -1 for null output pointers.
#[unsafe(no_mangle)]
pub extern "C" fn exa_ui_visible_range(
    item_count: usize,
    first_visible: usize,
    visible_count: usize,
    overscan: usize,
    out_start: *mut usize,
    out_end: *mut usize,
) -> c_int {
    if out_start.is_null() || out_end.is_null() {
        return -1;
    }
    let range = visible_range(item_count, first_visible, visible_count, overscan);
    // SAFETY: pointers are non-null; caller must provide valid writable usize pointers.
    unsafe {
        out_start.write(range.start);
        out_end.write(range.end);
    }
    0
}

/// Validate UTF-8 without modifying the supplied bytes.
#[unsafe(no_mangle)]
pub extern "C" fn exa_text_is_valid_utf8(data: *const u8, length: usize) -> c_int {
    if data.is_null() {
        return if length == 0 { 1 } else { 0 };
    }
    // SAFETY: caller guarantees data points to length readable bytes.
    let bytes = unsafe { slice::from_raw_parts(data, length) };
    if str::from_utf8(bytes).is_ok() { 1 } else { 0 }
}

/// Clamp a scroll offset. Invalid/non-finite values become zero.
#[unsafe(no_mangle)]
pub extern "C" fn exa_ui_clamp_scroll(offset: f32, maximum: f32) -> f32 {
    clamp_scroll_offset(offset, maximum)
}

/// Return loading progress in the inclusive range [0, 1].
#[unsafe(no_mangle)]
pub extern "C" fn exa_loading_progress(completed: u64, total: u64) -> f32 {
    LoadingProgress::new(completed, total).fraction()
}
