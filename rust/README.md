# ExA Client Rust performance core

Rust 2024 crate intended to be linked into the Android luanti shared library.
It does not replace C++, Irrlicht, SDL, or the Android Java/Kotlin layer.

Initial C ABI:
- exa_ui_visible_range: calculates a virtual-list row window with overscan.
- exa_ui_clamp_scroll: clamps offsets and rejects non-finite values.
- exa_text_is_valid_utf8: validates bytes without rewriting Unicode text.
- exa_loading_progress: calculates bounded progress.
- exa_engine_name / exa_engine_version: read-only static C strings.

The first implementation is allocation-free and dependency-free. It is an
integration seam, not proof that the UI has already been migrated or made
faster. C++ must call these APIs in measured hot paths before runtime behavior
changes. Rendering, glyph shaping, font fallback, touch handling and resource
I/O remain in the existing engine.

Host tests:
    cargo test --manifest-path rust/Cargo.toml
