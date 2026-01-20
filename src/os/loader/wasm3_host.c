#include "wasm3.h"

extern void wasm_env_rect(int32_t stroke, int32_t fill, int32_t x, int32_t y, int32_t w, int32_t h);
extern void wasm_env_oval(int32_t stroke, int32_t fill, int32_t x, int32_t y, int32_t w, int32_t h);
extern void wasm_env_line(int32_t color, int32_t x1, int32_t y1, int32_t x2, int32_t y2);
extern void wasm_env_hline(int32_t color, int32_t x, int32_t y, int32_t len);
extern void wasm_env_vline(int32_t color, int32_t x, int32_t y, int32_t len);
extern void wasm_env_blit(const uint16_t *sprite, int32_t x, int32_t y, uint32_t w, uint32_t h, uint32_t src_x, uint32_t src_y, uint32_t stride, uint32_t flags);
extern void wasm_env_text(uint32_t text_color, uint32_t bg_color, const uint8_t *text, uint32_t len, int32_t x, int32_t y);
extern void wasm_env_tone(uint32_t frequency, uint32_t duration, uint32_t volume, uint32_t flags);
extern uint32_t wasm_env_read_flash(uint32_t offset, uint8_t *dst, uint32_t len);
extern void wasm_env_write_flash_page(uint32_t page, const uint8_t *src);
extern uint32_t wasm_env_rand(void);
extern void wasm_env_trace(const uint8_t *text, uint32_t len);

m3ApiRawFunction(env_rect) {
    m3ApiGetArg(int32_t, stroke);
    m3ApiGetArg(int32_t, fill);
    m3ApiGetArg(int32_t, x);
    m3ApiGetArg(int32_t, y);
    m3ApiGetArg(int32_t, w);
    m3ApiGetArg(int32_t, h);
    wasm_env_rect(stroke, fill, x, y, w, h);
    m3ApiSuccess();
}

m3ApiRawFunction(env_oval) {
    m3ApiGetArg(int32_t, stroke);
    m3ApiGetArg(int32_t, fill);
    m3ApiGetArg(int32_t, x);
    m3ApiGetArg(int32_t, y);
    m3ApiGetArg(int32_t, w);
    m3ApiGetArg(int32_t, h);
    wasm_env_oval(stroke, fill, x, y, w, h);
    m3ApiSuccess();
}

m3ApiRawFunction(env_line) {
    m3ApiGetArg(int32_t, color);
    m3ApiGetArg(int32_t, x1);
    m3ApiGetArg(int32_t, y1);
    m3ApiGetArg(int32_t, x2);
    m3ApiGetArg(int32_t, y2);
    wasm_env_line(color, x1, y1, x2, y2);
    m3ApiSuccess();
}

m3ApiRawFunction(env_hline) {
    m3ApiGetArg(int32_t, color);
    m3ApiGetArg(int32_t, x);
    m3ApiGetArg(int32_t, y);
    m3ApiGetArg(int32_t, len);
    wasm_env_hline(color, x, y, len);
    m3ApiSuccess();
}

m3ApiRawFunction(env_vline) {
    m3ApiGetArg(int32_t, color);
    m3ApiGetArg(int32_t, x);
    m3ApiGetArg(int32_t, y);
    m3ApiGetArg(int32_t, len);
    wasm_env_vline(color, x, y, len);
    m3ApiSuccess();
}

m3ApiRawFunction(env_blit) {
    m3ApiGetArgMem(uint16_t *, sprite);
    m3ApiGetArg(int32_t, x);
    m3ApiGetArg(int32_t, y);
    m3ApiGetArg(uint32_t, w);
    m3ApiGetArg(uint32_t, h);
    m3ApiGetArg(uint32_t, src_x);
    m3ApiGetArg(uint32_t, src_y);
    m3ApiGetArg(uint32_t, stride);
    m3ApiGetArg(uint32_t, flags);
    wasm_env_blit(sprite, x, y, w, h, src_x, src_y, stride, flags);
    m3ApiSuccess();
}

m3ApiRawFunction(env_text) {
    m3ApiGetArg(uint32_t, text_color);
    m3ApiGetArg(uint32_t, bg_color);
    m3ApiGetArgMem(uint8_t *, text);
    m3ApiGetArg(uint32_t, len);
    m3ApiGetArg(int32_t, x);
    m3ApiGetArg(int32_t, y);
    wasm_env_text(text_color, bg_color, text, len, x, y);
    m3ApiSuccess();
}

m3ApiRawFunction(env_tone) {
    m3ApiGetArg(uint32_t, frequency);
    m3ApiGetArg(uint32_t, duration);
    m3ApiGetArg(uint32_t, volume);
    m3ApiGetArg(uint32_t, flags);
    wasm_env_tone(frequency, duration, volume, flags);
    m3ApiSuccess();
}

m3ApiRawFunction(env_read_flash) {
    m3ApiReturnType(uint32_t)
    m3ApiGetArg(uint32_t, offset);
    m3ApiGetArgMem(uint8_t *, dst);
    m3ApiGetArg(uint32_t, len);
    uint32_t read_len = wasm_env_read_flash(offset, dst, len);
    m3ApiReturn(read_len);
}

m3ApiRawFunction(env_write_flash_page) {
    m3ApiGetArg(uint32_t, page);
    m3ApiGetArgMem(uint8_t *, src);
    wasm_env_write_flash_page(page, src);
    m3ApiSuccess();
}

m3ApiRawFunction(env_rand) {
    m3ApiReturnType(uint32_t)
    m3ApiReturn(wasm_env_rand());
}

m3ApiRawFunction(env_trace) {
    m3ApiGetArgMem(uint8_t *, text);
    m3ApiGetArg(uint32_t, len);
    wasm_env_trace(text, len);
    m3ApiSuccess();
}

