export const WIDTH = 160;
export const HEIGHT = 128;

export const FLASH_PAGE_SIZE = 256;
export const FLASH_PAGE_COUNT = 8000;

export const CRASH_TITLE = "SYCL BADGE SIM";

// Memory layout
export const ADDR_CONTROLS = 0x04;
export const ADDR_LIGHT_LEVEL = 0x06;
export const ADDR_NEOPIXELS = 0x08;
export const ADDR_RED_LED = 0x1c;
export const ADDR_BATTERY_LEVEL = 0x1e;
export const ADDR_FRAMEBUFFER = 0x20;

export const CONTROLS_START = 1;
export const CONTROLS_SELECT = 2;
export const CONTROLS_A = 4;
export const CONTROLS_B = 8;

export const CONTROLS_CLICK = 16;
export const CONTROLS_UP = 32;
export const CONTROLS_DOWN = 64;
export const CONTROLS_LEFT = 128;
export const CONTROLS_RIGHT = 256;

// Flags for Runtime.pauseState
export const PAUSE_CRASHED = 1;
export const PAUSE_REBOOTING = 2;

export const OPTIONAL_COLOR_NONE = -1;
