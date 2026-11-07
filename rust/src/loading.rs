//! Allocation-free loading state helpers.
//! Existing C++ code remains responsible for file I/O and scheduling.

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct LoadingProgress {
    completed: u64,
    total: u64,
}

impl LoadingProgress {
    pub const fn new(completed: u64, total: u64) -> Self {
        Self { completed, total }
    }

    pub fn fraction(self) -> f32 {
        if self.total == 0 {
            return 1.0;
        }
        (self.completed.min(self.total) as f64 / self.total as f64) as f32
    }

    pub const fn is_complete(self) -> bool {
        self.total == 0 || self.completed >= self.total
    }
}
