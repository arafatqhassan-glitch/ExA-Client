//! UTF-8 validation helpers.
//! Text is never normalized or rewritten: names, translations and chat stay exact.

pub fn is_valid_utf8(bytes: &[u8]) -> bool {
    std::str::from_utf8(bytes).is_ok()
}

#[cfg(test)]
mod tests {
    use super::is_valid_utf8;

    #[test]
    fn accepts_unicode_without_rewriting_it() {
        assert!(is_valid_utf8("नमस्ते 🌄 café".as_bytes()));
    }

    #[test]
    fn rejects_invalid_sequences() {
        assert!(!is_valid_utf8(&[0xF0, 0x28, 0x8C, 0x28]));
    }
}
