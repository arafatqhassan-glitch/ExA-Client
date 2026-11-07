# Optional Rust static library for the Android Luanti shared library.
# If Cargo is unavailable, preserve the original C++-only build.
if(ANDROID)
    option(EXA_ENABLE_RUST "Build and link the ExA Rust performance core" ON)
    if(EXA_ENABLE_RUST)
        find_program(EXA_CARGO_EXECUTABLE cargo)
        if(NOT EXA_CARGO_EXECUTABLE)
            message(WARNING "Cargo was not found; building the original C++ engine without Rust.")
        else()
            if(CMAKE_ANDROID_ARCH_ABI STREQUAL "arm64-v8a")
                set(EXA_RUST_TARGET "aarch64-linux-android")
                set(EXA_RUST_LINKER_PREFIX "aarch64-linux-android")
            elseif(CMAKE_ANDROID_ARCH_ABI STREQUAL "armeabi-v7a")
                set(EXA_RUST_TARGET "armv7-linux-androideabi")
                set(EXA_RUST_LINKER_PREFIX "armv7a-linux-androideabi")
            elseif(CMAKE_ANDROID_ARCH_ABI STREQUAL "x86")
                set(EXA_RUST_TARGET "i686-linux-android")
                set(EXA_RUST_LINKER_PREFIX "i686-linux-android")
            elseif(CMAKE_ANDROID_ARCH_ABI STREQUAL "x86_64")
                set(EXA_RUST_TARGET "x86_64-linux-android")
                set(EXA_RUST_LINKER_PREFIX "x86_64-linux-android")
            else()
                message(FATAL_ERROR "Unsupported Android ABI for ExA Rust: ${CMAKE_ANDROID_ARCH_ABI}")
            endif()

            if(NOT CMAKE_ANDROID_NDK)
                message(FATAL_ERROR "CMAKE_ANDROID_NDK is required to build the ExA Rust Android library.")
            endif()

            if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Linux")
                set(EXA_NDK_HOST_TAG "linux-x86_64")
            elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin")
                set(EXA_NDK_HOST_TAG "darwin-x86_64")
            elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
                set(EXA_NDK_HOST_TAG "windows-x86_64")
            else()
                message(FATAL_ERROR "Unsupported host for Android NDK Rust linking: ${CMAKE_HOST_SYSTEM_NAME}")
            endif()

            set(EXA_NDK_BIN "${CMAKE_ANDROID_NDK}/toolchains/llvm/prebuilt/${EXA_NDK_HOST_TAG}/bin")
            set(EXA_ANDROID_API "${CMAKE_SYSTEM_VERSION}")
            if(NOT EXA_ANDROID_API MATCHES "^[0-9]+$")
                set(EXA_ANDROID_API "21")
            endif()
            set(EXA_RUST_LINKER "${EXA_NDK_BIN}/${EXA_RUST_LINKER_PREFIX}${EXA_ANDROID_API}-clang")
            if(NOT EXISTS "${EXA_RUST_LINKER}")
                message(FATAL_ERROR "Rust Android linker wrapper not found: ${EXA_RUST_LINKER}")
            endif()

            string(TOUPPER "${EXA_RUST_TARGET}" EXA_RUST_TARGET_ENV)
            string(REPLACE "-" "_" EXA_RUST_TARGET_ENV "${EXA_RUST_TARGET_ENV}")

            set(EXA_RUST_TARGET_DIR "${CMAKE_BINARY_DIR}/exa-rust-target")
            set(EXA_RUST_ARCHIVE "${EXA_RUST_TARGET_DIR}/${EXA_RUST_TARGET}/release/libexa_client_rust.a")
            file(GLOB_RECURSE EXA_RUST_SOURCES CONFIGURE_DEPENDS
                "${CMAKE_SOURCE_DIR}/rust/src/*.rs")
            list(APPEND EXA_RUST_SOURCES
                "${CMAKE_SOURCE_DIR}/rust/Cargo.toml")

            add_custom_command(
                OUTPUT "${EXA_RUST_ARCHIVE}"
                COMMAND "${CMAKE_COMMAND}" -E env
                    "CARGO_TARGET_DIR=${EXA_RUST_TARGET_DIR}"
                    "CARGO_TARGET_${EXA_RUST_TARGET_ENV}_LINKER=${EXA_RUST_LINKER}"
                    "${EXA_CARGO_EXECUTABLE}" build
                    --manifest-path "${CMAKE_SOURCE_DIR}/rust/Cargo.toml"
                    --target "${EXA_RUST_TARGET}"
                    --release
                WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
                DEPENDS ${EXA_RUST_SOURCES}
                COMMENT "Building ExA Rust core for ${EXA_RUST_TARGET}"
                VERBATIM
            )

            add_custom_target(exa_rust_build DEPENDS "${EXA_RUST_ARCHIVE}")
            add_dependencies(${PROJECT_NAME} exa_rust_build)
            target_include_directories(${PROJECT_NAME} PRIVATE
                "${CMAKE_SOURCE_DIR}/rust/include")
            target_link_libraries(${PROJECT_NAME} PRIVATE
                "${EXA_RUST_ARCHIVE}" log android dl m)
            # Pull the Rust FFI object into libluanti.so so its C ABI is present.
            target_link_options(${PROJECT_NAME} PRIVATE "-Wl,-u,exa_ui_visible_range")
            message(STATUS "ExA Rust core enabled for ${CMAKE_ANDROID_ARCH_ABI}")
        endif()
    endif()
endif()
