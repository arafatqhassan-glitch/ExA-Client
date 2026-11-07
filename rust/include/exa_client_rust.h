#pragma once

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

const char *exa_engine_name(void);
const char *exa_engine_version(void);

int exa_ui_visible_range(
    size_t item_count,
    size_t first_visible,
    size_t visible_count,
    size_t overscan,
    size_t *out_start,
    size_t *out_end);

int exa_text_is_valid_utf8(const uint8_t *data, size_t length);
float exa_ui_clamp_scroll(float offset, float maximum);
float exa_loading_progress(uint64_t completed, uint64_t total);

#ifdef __cplusplus
}
#endif
