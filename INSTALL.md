# Add the starter to ExA Client

1. Copy the `rust/` directory into the repository root.
2. Copy `cmake/ExAClientRust.cmake` into the repository's `cmake/` directory.
3. Apply `INTEGRATION.patch` to `src/CMakeLists.txt`, or manually insert the
   shown include block immediately before `endif(BUILD_CLIENT)` in the client
   target section.
4. Run host tests with `cargo test --manifest-path rust/Cargo.toml`.
5. On Android builds, install Cargo and the Rust target matching the selected
   ABI. CMake invokes Cargo and links the generated static library into the
   `luanti` shared library.

If Cargo is absent, the CMake module warns and leaves the original C++ build
unchanged. The first version links the Rust FFI into libluanti.so but does not
yet reroute the renderer or text layout to Rust. That next step requires
calling the C ABI from the actual C++ UI/resource hot paths and benchmarking.
