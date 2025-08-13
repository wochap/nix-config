// OLED Protection Shader Parameters

// OLED_MONITOR: -1 for all monitors, or set to a specific monitor index
#define OLED_MONITOR -1

// OLED_FILL_COLOR: Fill color for checker pattern (vec4 RGBA, 0-1 range)
// Example: Black = vec4(0.,0.,0.,1.), White = vec4(1.,1.,1.,1.)
#define OLED_FILL_COLOR vec4(0.,0.,0.,1.)

// OLED_SWAP_INTERVAL: Swap interval in seconds (recommended: 5–10)
#define OLED_SWAP_INTERVAL 10.0

// OLED_PIXEL_SIZE: Size of each checker square (1.0 = 1px, higher = bigger)
#define OLED_PIXEL_SIZE 1.0

// Optional: Swap pattern logic (uncomment to invert logic)
// #define OLED_SWAP_PIXELS

// Optional: Restrict effect to area (vec4(x, y, w, h)), in px
#define OLED_AREA 0.,0.,40.,1800.

// Optional: Invert area logic (uncomment to invert area mask)
// #define OLED_INVERT_AREA

