//! Rust performance core for ExA Client.
//! C++ remains responsible for rendering and platform UI.

pub mod ffi;
pub mod loading;
pub mod performance;
pub mod ui;

pub const ENGINE_NAME: &str = "ExA Client";
pub const ENGINE_VERSION: &str = "1.5.1";

#[cfg(test)]
mod tests {
    use crate::loading::LoadingProgress;

    #[test]
    fn loading_progress_is_bounded() {
        assert_eq!(LoadingProgress::new(3, 2).fraction(), 1.0);
        assert_eq!(LoadingProgress::new(0, 0).fraction(), 1.0);
        assert_eq!(LoadingProgress::new(1, 4).fraction(), 0.25);
    }
}
