/* Taken from https://github.com/djpohly/dwl/issues/466 */
#define COLOR(hex)    { ((hex >> 24) & 0xFF) / 255.0f, \
                        ((hex >> 16) & 0xFF) / 255.0f, \
                        ((hex >> 8) & 0xFF) / 255.0f, \
                        (hex & 0xFF) / 255.0f }
/* appearance */
static const int sloppyfocus               = 1;  /* focus follows mouse */
static const int bypass_surface_visibility = 0;  /* 1 means idle inhibitors will disable idle tracking even if it's surface isn't visible  */
static const unsigned int borderpx         = 1;  /* border pixel of windows */
static const unsigned int borderspx        = 0;  /* width of the border that start from outside the windows */
static const unsigned int borderepx        = 0;  /* width of the border that start from inside the windows */
static const unsigned int borderspx_offset = 0;  /* offset of the border that start from outside the windows */
static const unsigned int borderepx_negative_offset = 1; /* offset of the border that start from inside the windows */
static const int draw_minimal_borders      = 1; /* merge adjacent borders */
static const float rootcolor[] = COLOR(0x@base@ff);
static const float bordercolor[] = COLOR(0x@border@ff);
static const float borderscolor[] = COLOR(0x@border@ff); /* color of the border that start from outside the windows */
static const float borderecolor[] = COLOR(0x@crust@ff); /* color of the border that start from inside the windows */
static const int border_color_type = BrdOriginal; /* borders to be colored (focuscolor, urgentcolor) */
static const int borders_only_floating = 1;
static const float focuscolor[] = COLOR(0x@surface0@ff);
static const float urgentcolor[] = COLOR(0x@red@ff);
/* To conform the xdg-protocol, set the alpha to zero to restore the old behavior */
static const float fullscreen_bg[]         = {0.1f, 0.1f, 0.1f, 0.0f}; /* You can also use glsl colors */
static const char *cursor_theme = "@cursorName@";
static const char cursor_size[] = "@cursorSize@";
static const unsigned int swipe_min_threshold = 0;
static const int respect_monitor_reserved_area = 0;  /* 1 to monitor center while respecting the monitor's reserved area, 0 to monitor center */

static const int opacity = 0; /* flag to enable opacity */
static const float opacity_inactive = 0.5;
static const float opacity_active = 1.0;

static const int shadow = 1;
static const int shadow_only_floating = 1;
static const float shadow_color[4] = COLOR(0x@shadow@80);
static const float shadow_color_focus[4] = COLOR(0x@shadow@80);
static const int shadow_blur_sigma = 14;
static const int shadow_blur_sigma_focus = 28;
static const char *const shadow_ignore_list[] = { NULL }; /* list of app-id to ignore */

static const int corner_radius = 4; /* 0 disables corner_radius */
static const int corner_radius_inner = 4; /* 0 disables corner_radius */
static const int corner_radius_only_floating = 1; /* only apply corner_radius and corner_radius_inner to floating windows */

static const int blur = 0; /* flag to enable blur */
static const int blur_xray = 1; /* flag to make transparent fs and floating windows display your background */
static const int blur_ignore_transparent = 1;
static const struct blur_data blur_data = {
  .radius = 5,
  .num_passes = 3,
  .noise = (float)0.02,
  .brightness = (float)0.9,
  .contrast = (float)0.9,
  .saturation = (float)1.1,
};

enum {
  VIEW_L = -1,
  VIEW_R = 1,
  SHIFT_L = -2,
  SHIFT_R = 2,
} RotateTags;
enum {
	BROWSER,
	LAYOUT,
	TUI,
	NOTIFICATION,
  KB_INHIBIT,
};
const char *modes_labels[] = {
	"browser",
	"layout",
	"tui",
	"notification",
	"kb inhibit",
};

static const Env envs[] = {
  /* variable            value */
  { "XDG_CURRENT_DESKTOP", "dwl" },
  { "XDG_SESSION_DESKTOP", "dwl" },
};

/* Autostart */
static const char *const autostart[] = {
  "uwsm", "finalize", "XDG_CURRENT_DESKTOP", "XDG_SESSION_TYPE", "XDG_SESSION_DESKTOP", NULL,

  "configure-gtk", NULL,

  NULL /* terminate */
};

/* tagging - TAGCOUNT must be no greater than 31 */
#define TAGCOUNT (9)

/* logging */
static int log_level = WLR_ERROR;

static const char bing_gpt_appid[] = "msedge-www.bing.com__chat-Default";
static const char chat_gpt_appid[] = "chrome-chat.openai.com__-Default";
static const char ollama_appid[] = "chrome-ollama.wochap.local__-Default";
static const char openwebui_appid[] = "chrome-openwebui.wochap.local__-Default";
static const char ytmusic_appid[] = "chrome-music.youtube.com__-Default";

/* NOTE: ALWAYS keep a rule declared even if you don't use rules (e.g leave at least one example) */
static const Rule rules[] = {
	/* app_id                    title       tags mask  isfloating  issticky  monitor  x    y    width height  scratchkey */
	/* examples:
	{ "Gimp",                    NULL,       0,         1,          0,        -1, 	   0, 	0,   500,  400,    0 },
	*/
	// { "mpv",                     NULL,       0,         1,          0,        -1,      0,   0,   0.8f, 0.8f, 0 },
	// { "imv",                     NULL,       0,         1,          0,        -1,      0,   0,   0,    0,      0 },
	{ "^Zoom",                   "^zoom$",   0,         1,          0,        -1,      0,   0,   0,    0,      0 },
	{ "^Zoom",                   "^menu window$", 0,    1,          0,        -1,      0,   0,   0,    0,      0 },
	{ "^Zoom",                   "^Settings$", 0,       1,          0,        -1,      0,   0,   0,    0,      0 },
	{ "^Zoom",                   "^Zoom Workplace$", 0, 1,          0,        -1,      0,   0,   0,    0,      0 },
	{ "^Zoom",                   "^cc_receiver$", 0,    1,          0,        -1,      0,   0,   0,    0,      0 },
	{ "xwaylandvideobridge",     NULL,       1 << 9,    1,          0,        -1,      0,   0,   0,    0,      'x' },
	{ "^[tT]hunar$",             NULL,       0,         1,          0,        -1,      0,   0,   0,    0,      'f' },
	{ "file-roller",             NULL,       0,         1,          0,        -1,      0,   0,   0,    0,      0 },
	{ "org.gnome.Calculator",    NULL,       0,         1,          0,        -1,      0,   0,   0,    0,      0 },
	{ "showmethekey-gtk",        NULL,       0,         1,          1,        -1,      -7,  -7,  500,  100,    0 },
	{ "xdg-desktop-portal-gtk",  NULL,       0,         1,          0,        -1,      0,   0,   0,    0,      0 },
	{ "Slack",                   NULL,       1 << 3,    0,          0,        -1,      0,   0,   0,    0,      0 },
	{ "discord",                 NULL,       1 << 3,    0,          0,        -1,      0,   0,   0,    0,      0 },
	{ "discord",                 "Discord Updater", 1 << 3, 1,      0,        -1,      0,   0,   0,    0,      0 },
	{ "com.gabm.satty",          NULL,       0,         1,          0,        -1,      0,   0,   1200, 800,    0 },

	{ NULL,                      "^Extracting Files.*", 0, 1,       0,        -1,      0,   0,   0,    0,      0 },
	{ NULL, ".com is sharing your screen.$", 1 << 9,    1,          0,        -1,      0,   0,   0,    0,      0 },

	{ bing_gpt_appid,            NULL,       0,         1,          0,        -1,      0,   0,   1200, 800,    'g' },
	{ chat_gpt_appid,            NULL,       0,         1,          0,        -1,      0,   0,   1200, 800,    'c' },
	{ ollama_appid,              NULL,       0,         1,          0,        -1,      0,   0,   1200, 800,    'o' },
	{ openwebui_appid,           NULL,       0,         1,          0,        -1,      0,   0,   1200, 800,    'w' },
	{ ytmusic_appid,             NULL,       0,         1,          0,        -1,      0,   0,   1200, 800,    'y' },
	{ "firefox",                 NULL,       1 << 4,    0,          0,        -1,      0,   0,   0,    0,      0 },
	{ "brave-browser",           NULL,       1 << 7,    0,          0,        -1,      0,   0,   0,    0,      0 },
	{ "microsoft-edge",          NULL,       1 << 8,    0,          0,        -1,      0,   0,   0,    0,      0 },

// { "^foot-.*",                NULL,       1 << 1,    0,          0,        -1,      0,   0,   0,    0,      0 },
// { "^footclient-.*",          NULL,       1 << 1,    0,          0,        -1,      0,   0,   0,    0,      0 },
// { "^kitty-.*",               NULL,       1 << 1,    0,          0,        -1,      0,   0,   0,    0,      0 },
// { "^alacritty-.*",           NULL,       1 << 1,    0,          0,        -1,      0,   0,   0,    0,      0 },

	{ "kitty-scratch",           NULL,       0,         1,          0,        -1,      0,   0,   1200, 800,    'i' },
	{ "tui-monitor",             NULL,       0,         1,          0,        -1,      0,   0,   1200, 800,    'm' },
	{ "tui-notes$",              NULL,       0,         1,          0,        -1,      0,   0,   1200, 800,    'n' },
	{ "tui-notes-obsidian",      NULL,       0,         1,          0,        -1,      0,   0,   1200, 800,    'b' },
	{ "tui-email",               NULL,       0,         1,          0,        -1,      0,   0,   1200, 800,    'e' },
	{ "tui-rss",                 NULL,       0,         1,          0,        -1,      0,   0,   1200, 800,    'r' },
	{ "tui-music",               NULL,       0,         1,          0,        -1,      0,   0,   1200, 800,    'u' },
	{ "tui-notification-center", NULL,       0,         1,          0,        -1,      0,   0,   1200, 800,    'd' },
	{ "tui-calendar",            NULL,       0,         1,          0,        -1,      0,   0,   1200, 800,    'k' },
	{ "tui-bookmarks",           NULL,       0,         1,          0,        -1,      0,   0,   1200, 800,    0 },

	/* x, y, width, heigh are floating only
	* When x or y == 0 the client is placed at the center of the screen,
	* when width or height == 0 the default size of the client is used*/
};

/* layout(s) */
static const Layout layouts[] = {
	/* symbol     arrange function */
	{ "[]=",      tile },
	{ "TTT",      bstack },
	{ "[M]",      monocle },
	// { "@|@",      snail },
	{ "><>",      NULL },    /* no layout function means floating behavior */
	{ NULL,       NULL },
};

/* size(s) */
static const Size sizes[] = {
	/* width   height */
	{ 1200,    800 },
};

enum layout_types {
  LAYOUT_TILE,
  LAYOUT_BSTACK,
  LAYOUT_MONOCLE,
  // LAYOUT_SNAIL,
  LAYOUT_FLOAT,
};

/* monitors */
/* (x=-1, y=-1) is reserved as an "autoconfigure" monitor position indicator
 * WARNING: negative values other than (-1, -1) cause problems with Xwayland clients
 * https://gitlab.freedesktop.org/xorg/xserver/-/issues/899
*/
/* NOTE: ALWAYS add a fallback rule, even if you are completely sure it won't be used */
static const MonitorRule monrules[] = {
	/* name       mfact nmaster scale layout       rotate/reflect                x    y */
	/* example of a HiDPI laptop monitor:
	{ "eDP-1",    0.5,  1,      2,    &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL,   -1,  -1 },
	*/
  // { "DP-1",     0.5, 1,      1,    &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL,   -1,  -1 },
  // { "eDP-1",    0.5, 1,      2,    &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL,   -1,  -1 },
	/* defaults */
	{ NULL,       0.5f,  1,      2,    &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL,   -1,  -1 },
};

/* keyboard */
static const struct xkb_rule_names xkb_rules[] = {
  {
    /* can specify fields: rules, model, layout, variant, options */
    /* example:
    .options = "ctrl:nocaps",
    */
    .layout = "us",
    .options = "",
  },
  {
    .layout = "us",
    .options = "compose:ralt",
  }
};

static const int repeat_rate = 50;
static const int repeat_delay = 300;

/* Trackpad */
static const int tap_to_click = 1;
static const int tap_and_drag = 1;
static const int drag_lock = 0;
static const int natural_scrolling = 1;
static const int disable_while_typing = LIBINPUT_CONFIG_DWTP_DISABLED;
static const int left_handed = 0;
static const int middle_button_emulation = 1;

/* Scroll sensitivity */
static const double scroll_factor = 0.5f;

/* You can choose between:
LIBINPUT_CONFIG_SCROLL_NO_SCROLL
LIBINPUT_CONFIG_SCROLL_2FG
LIBINPUT_CONFIG_SCROLL_EDGE
LIBINPUT_CONFIG_SCROLL_ON_BUTTON_DOWN
*/
static const enum libinput_config_scroll_method scroll_method = LIBINPUT_CONFIG_SCROLL_2FG;

/* You can choose between:
LIBINPUT_CONFIG_CLICK_METHOD_NONE
LIBINPUT_CONFIG_CLICK_METHOD_BUTTON_AREAS
LIBINPUT_CONFIG_CLICK_METHOD_CLICKFINGER
*/
static const enum libinput_config_click_method click_method = LIBINPUT_CONFIG_CLICK_METHOD_CLICKFINGER;

/* You can choose between:
LIBINPUT_CONFIG_SEND_EVENTS_ENABLED
LIBINPUT_CONFIG_SEND_EVENTS_DISABLED
LIBINPUT_CONFIG_SEND_EVENTS_DISABLED_ON_EXTERNAL_MOUSE
*/
static const uint32_t send_events_mode = LIBINPUT_CONFIG_SEND_EVENTS_ENABLED;

/* You can choose between:
LIBINPUT_CONFIG_ACCEL_PROFILE_FLAT
LIBINPUT_CONFIG_ACCEL_PROFILE_ADAPTIVE
*/
static const enum libinput_config_accel_profile accel_profile = LIBINPUT_CONFIG_ACCEL_PROFILE_ADAPTIVE;
static const double accel_speed = -0.2;
/* You can choose between:
LIBINPUT_CONFIG_TAP_MAP_LRM -- 1/2/3 finger tap maps to left/right/middle
LIBINPUT_CONFIG_TAP_MAP_LMR -- 1/2/3 finger tap maps to left/middle/right
*/
static const enum libinput_config_tap_button_map button_map = LIBINPUT_CONFIG_TAP_MAP_LRM;

/* If you want to use the windows key for MODKEY, use WLR_MODIFIER_LOGO */
#define MODKEY WLR_MODIFIER_LOGO
#define MOD_ALT WLR_MODIFIER_ALT
#define MOD_CONTROL WLR_MODIFIER_CTRL
#define MOD_SHIFT WLR_MODIFIER_SHIFT
#define MOD_LOGO WLR_MODIFIER_LOGO
#define MOD_NONE 0

/* { MODKEY, KEY,                       remembertagsview, {.ui = TAG} }, \ */
#define TAGKEYS(KEY,TAG) \
  { MODKEY,  KEY,                      view,       {.ui = 1 << TAG} }, \
	{ MODKEY|MOD_CONTROL, KEY,           toggleview, {.ui = 1 << TAG} }, \
	{ MODKEY|MOD_SHIFT, KEY,             tag,        {.ui = 1 << TAG} }, \
	{ MODKEY|MOD_CONTROL|MOD_SHIFT, KEY, toggletag,  {.ui = 1 << TAG} }

/* helper for spawning shell commands in the pre dwm-5.0 fashion */
#define SHCMD(cmd) { .v = (const char*[]){ "sh", "-c", cmd, NULL } }

// same as SHCMD but adds uwsm-app
#define SHCMD_UWSM(cmd) { .v = (const char*[]){ "sh", "-c", "uwsm-app -- " cmd, NULL } }

// same as SHCMD_UWSM but adds scratchkey
#define SHCMD_UWSM_SK(scratchkey, cmd) { .v = (const char*[]){ scratchkey, "sh", "-c", "uwsm-app -- " cmd, NULL } }

/* commands */
#define RUN(...)   { .v = (const char*[]){ __VA_ARGS__, NULL } }

#include "shiftview.c"

#include "keys.h"
static const Key keys[] = {
	/* count key_sequences                                function          argument */


  // ### SYSTEM KEYBINDINGS

  // Open scratchpad terminal
  { MODKEY, Key_i, raiserunnamedscratchpad, SHCMD_UWSM_SK("i", "~/.config/kitty/scripts/kitty-scratch.sh") },

  // Lock screen
	{ MODKEY, Key_l, spawn, SHCMD("hyprlock-start") },

  // Open power menu
  { MODKEY, Key_Escape, spawn, SHCMD_UWSM("tofi-powermenu") },

  // Open app launcher
	{ MODKEY, Key_space, spawn, SHCMD_UWSM("tofi-launcher") },

  // Take fullscreen screenshoot
  { MODKEY, Key_Print, spawn, SHCMD_UWSM("takeshot --now") },

  // Open calc
  { MODKEY, Key_c, spawn, SHCMD_UWSM("tofi-calc") },

  // Show clipboard
  { MODKEY, Key_v, spawn, SHCMD_UWSM("clipboard-manager --menu") },

  // Clear clipboard
  { MODKEY|MOD_SHIFT, Key_v, spawn, SHCMD("clipboard-manager --clear") },

  // Show emojis
  { MODKEY, Key_e, spawn, SHCMD_UWSM("tofi-emoji") },

  // Toggle bars
  { MODKEY, Key_b, spawn, SHCMD("toggle-bars") },

  // Toggle idle inhibitor
  { MODKEY, Key_m, spawn, SHCMD("matcha-toggle-mode --toggle") },

  // Toggle offlinemsmtp
  { MODKEY, Key_o, spawn, SHCMD("offlinemsmtp-toggle-mode --toggle") },


  // ### WM KEYBINDINGS

  // Close focused view
  { MODKEY|MOD_SHIFT, Key_w, killclient, {0} },

  // Toggle float
  { MODKEY, Key_s, togglefloating, {0} },

  // Toggle fullscreen
  { MODKEY, Key_f, togglefullscreen, {0} },
  { MODKEY|MOD_SHIFT, Key_f, togglefakefullscreen, {0} },

  // Set sticky
  { MODKEY|MOD_CONTROL, Key_y, togglesticky, {0} },
  { MODKEY|MOD_CONTROL, Key_0, tag, {.ui = ~0} },

  // Focus direction
  // TODO: pick a window to focus
  { MODKEY, Key_n, focusstack, {.i = +1} },
  { MODKEY, Key_p, focusstack, {.i = -1} },
  { MODKEY, Key_Down, focusdir, {.ui = 3} },
  { MODKEY, Key_Up, focusdir, {.ui = 2} },
  { MODKEY, Key_Left, focusdir, {.ui = 0} },
  { MODKEY, Key_Right, focusdir, {.ui = 1} },

  // Swap direction
  // TODO: pick a window to swap with
  { MODKEY|MOD_SHIFT, Key_n, movestack, {.i = +1} },
  { MODKEY|MOD_SHIFT, Key_p, movestack, {.i = -1} },
  { MODKEY|MOD_SHIFT, Key_Down, swapdir, {.ui = 3} },
  { MODKEY|MOD_SHIFT, Key_Up, swapdir, {.ui = 2} },
  { MODKEY|MOD_SHIFT, Key_Left, swapdir, {.ui = 0} },
  { MODKEY|MOD_SHIFT, Key_Right, swapdir, {.ui = 1} },

  // Resize floating windows
  { MODKEY|MOD_ALT|MOD_SHIFT, Key_Down, moveresizekb, {.v = (int []){ 0, 0, 0, 40 }}},
  { MODKEY|MOD_ALT|MOD_SHIFT, Key_Up, moveresizekb, {.v = (int []){ 0, 0, 0, -40 }}},
  { MODKEY|MOD_ALT|MOD_SHIFT, Key_Right, moveresizekb, {.v = (int []){ 0, 0, 40, 0 }}},
  { MODKEY|MOD_ALT|MOD_SHIFT, Key_Left, moveresizekb, {.v = (int []){ 0, 0, -40, 0 }}},

  // Move floating windows
  { MODKEY|MOD_ALT, Key_Down, moveresizekb, {.v = (int []){ 0, 40, 0, 0 }}},
  { MODKEY|MOD_ALT, Key_Up, moveresizekb, {.v = (int []){ 0, -40, 0, 0 }}},
  { MODKEY|MOD_ALT, Key_Right, moveresizekb, {.v = (int []){ 40, 0, 0, 0 }}},
  { MODKEY|MOD_ALT, Key_Left, moveresizekb, {.v = (int []){ -40, 0, 0, 0 }}},

  // Focus next/previous tag
  { MODKEY, Key_comma, rotatetags, {.i = VIEW_L} },
  { MODKEY, Key_period, rotatetags, {.i = VIEW_R} },

  // Send focused view to the next/previous tag
  { MODKEY|MOD_SHIFT, Key_comma, rotatetags, {.i = SHIFT_L} },
  { MODKEY|MOD_SHIFT, Key_period, rotatetags, {.i = SHIFT_R} },

  // Bump focused view to the top of the layout stack
  { MODKEY, Key_Return, zoom, {0} },

  // Focus next/prev monitor
  { MODKEY, Key_bracketleft, focusmon, {.i = WLR_DIRECTION_LEFT} },
	{ MODKEY, Key_bracketright, focusmon, {.i = WLR_DIRECTION_RIGHT} },

  // Send focused view to the next/previous monitor
	{ MODKEY|WLR_MODIFIER_SHIFT, Key_bracketleft, tagmon, {.i = WLR_DIRECTION_LEFT} },
	{ MODKEY|WLR_MODIFIER_SHIFT, Key_bracketright, tagmon, {.i = WLR_DIRECTION_RIGHT} },


  // ### WM TAGS/VIEWS

  TAGKEYS( Key_1, 0),
  TAGKEYS( Key_2, 1),
  TAGKEYS( Key_3, 2),
  TAGKEYS( Key_4, 3),
  TAGKEYS( Key_5, 4),
  TAGKEYS( Key_6, 5),
  TAGKEYS( Key_7, 6),
  TAGKEYS( Key_8, 7),
  TAGKEYS( Key_9, 8),

  // Focus previous tags
  { MODKEY, Key_grave, view, {.ui = 0} },

  // Focus all tags
  { MODKEY, Key_0, view, {.ui = ~0} },


  // ### WM SCRATCHPAD

  // Open scratchpad
  { MODKEY, Key_d, togglescratchpad, {0} },

  // Send to scratchpad
  { MODKEY|WLR_MODIFIER_SHIFT, Key_d, toggleinscratchpad, {0} },

  // Open last named scratchpad
  { MODKEY|WLR_MODIFIER_SHIFT, Key_grave, focusprevnamedscratchpad, {0} },

  // ### APPLICATION KEYBINDINGS (Super + Alt + Key)

  // Open primary terminal
	{ MODKEY|MOD_ALT, Key_t, spawn, SHCMD_UWSM("footclient") },

  // Open file manager
  { MODKEY|MOD_ALT, Key_f, raiserunnamedscratchpad, SHCMD_UWSM_SK("f", "Thunar --name Thunar") },

  // Show ruler
  { MODKEY|MOD_ALT, Key_m, spawn, SHCMD_UWSM("ruler") },

  // Screencast/record region to mp4
  { MODKEY|MOD_ALT, Key_r, spawn, SHCMD_UWSM("recorder --area") },

  // Open screenshoot utility
  { MODKEY|MOD_ALT, Key_s, spawn, SHCMD_UWSM("takeshot --area") },

  // Open ocr utility
  { MODKEY|MOD_ALT, Key_o, spawn, SHCMD_UWSM("ocr") },

  // Open ocr math utility
  { MODKEY|MOD_ALT, Key_h, spawn, SHCMD_UWSM("ocr-math") },

  // Open color picker
  { MODKEY|MOD_ALT, Key_c, spawn, SHCMD_UWSM("color-picker") },

  // TODO: Magnifying glass
  { MODKEY|MOD_ALT, Key_z, spawn, SHCMD_UWSM("hyprmag --radius 250") },


  // ### MEDIA KEYBINDINGS

  { MOD_NONE, Key_XF86AudioRaiseVolume, spawn, SHCMD("progress-osd --volume +5%") },
  { MOD_NONE, Key_XF86AudioLowerVolume, spawn, SHCMD("progress-osd --volume -5%") },
  { MOD_NONE, Key_XF86AudioMute, spawn, SHCMD("progress-osd --volume-toggle") },

  { MOD_NONE, Key_XF86AudioNext, spawn, SHCMD("playerctl next") },
  { MOD_NONE, Key_XF86AudioPrev, spawn, SHCMD("playerctl previous") },
  { MOD_NONE, Key_XF86AudioStop, spawn, SHCMD("playerctl pause") },
  { MOD_NONE, Key_XF86AudioPlay, spawn, SHCMD("playerctl play-pause") },

  { MOD_NONE, Key_XF86MonBrightnessUp, spawn, SHCMD("progress-osd --backlight 5%+") },
  { MOD_NONE, Key_XF86MonBrightnessDown, spawn, SHCMD("progress-osd --backlight 5%-") },

  { MOD_NONE, Key_XF86KbdBrightnessUp, spawn, SHCMD("progress-osd --kbd-backlight 5%+") },
  { MOD_NONE, Key_XF86KbdBrightnessDown, spawn, SHCMD("progress-osd --kbd-backlight 5%-") },


  // ### OTHERS

  { MODKEY, Key_r, entermode, {.i = LAYOUT} },
  { MODKEY|MOD_ALT, Key_b, entermode, {.i = BROWSER} },
  { MODKEY|MOD_ALT, Key_u, entermode, {.i = TUI} },
  { MODKEY|MOD_ALT, Key_n, entermode, {.i = NOTIFICATION} },
  { MODKEY|MOD_ALT|MOD_CONTROL, Key_g, entermode, {.i = KB_INHIBIT} },
  { MODKEY|MOD_ALT|MOD_CONTROL|MOD_SHIFT, Key_m, create_output, {0} },
  { MODKEY|MOD_ALT, Key_x, raiserunnamedscratchpad, SHCMD_UWSM_SK("x", "xwaylandvideobridge") },
  { MODKEY|MOD_CONTROL|MOD_SHIFT, Key_l, switchxkbrule, {0} },
  { MODKEY|MOD_CONTROL|MOD_SHIFT, Key_q, quit, {0} },

	/* Ctrl-Alt-Backspace and Ctrl-Alt-Fx used to be handled by X server */
	{ MOD_CONTROL|MOD_ALT, Key_BackSpace, quit, {0} },
#define CHVT(KEY,n) { MOD_CONTROL|MOD_ALT,KEY, chvt, {.ui = (n)} }
	CHVT(Key_F1, 1), CHVT(Key_F2,  2),  CHVT(Key_F3,  3),  CHVT(Key_F4,  4),
	CHVT(Key_F5, 5), CHVT(Key_F6,  6),  CHVT(Key_F7,  7),  CHVT(Key_F8,  8),
	CHVT(Key_F9, 9), CHVT(Key_F10, 10), CHVT(Key_F11, 11), CHVT(Key_F12, 12),
};

static const Key lockedkeys[] = {
	/* Note that Shift changes certain key codes: c -> C, 2 -> at, etc. */
	/* modifier                  key                 function        argument */


  // ### OTHERS

  { MODKEY|MOD_CONTROL|MOD_SHIFT, Key_w, switchxkbrule, {0} },
  { MODKEY|MOD_CONTROL|MOD_SHIFT, Key_q, quit, {0} },


	/* Ctrl-Alt-Backspace and Ctrl-Alt-Fx used to be handled by X server */
	{ MOD_CONTROL|MOD_ALT, Key_BackSpace, quit, {0} },
#define CHVT(KEY,n) { MOD_CONTROL|MOD_ALT,KEY, chvt, {.ui = (n)} }
	CHVT(Key_F1, 1), CHVT(Key_F2,  2),  CHVT(Key_F3,  3),  CHVT(Key_F4,  4),
	CHVT(Key_F5, 5), CHVT(Key_F6,  6),  CHVT(Key_F7,  7),  CHVT(Key_F8,  8),
	CHVT(Key_F9, 9), CHVT(Key_F10, 10), CHVT(Key_F11, 11), CHVT(Key_F12, 12),
};

static const Modekey modekeys[] = {
	/* mode      modifier                  key                 function        argument */

#define EXIT_TO_NORMAL_MODE(mode_index, mod, keycode, func, arg) \
  { mode_index, { mod, keycode, func, arg } }, \
  { mode_index, { mod, keycode, entermode, {.i = NORMAL} } }

  EXIT_TO_NORMAL_MODE(LAYOUT, MOD_NONE, Key_c, movecenter, {0}),
  // To decrease/increase the main count
  { LAYOUT, { MOD_NONE, Key_Left, incnmaster, {.i = +1} } },
  { LAYOUT, { MOD_NONE, Key_Right, incnmaster, {.i = -1} } },
  // To increment/decrement the main ratio
  { LAYOUT, { MOD_SHIFT, Key_Left, setmfact, {.f = (float)-0.05} } },
  { LAYOUT, { MOD_SHIFT, Key_Right, setmfact, {.f = (float)+0.05} } },
  // To increment/decrement the client ratio
  { LAYOUT, { MOD_CONTROL|MOD_SHIFT, Key_Left, setcfact, {.f = -0.25} } },
  { LAYOUT, { MOD_CONTROL|MOD_SHIFT, Key_Right, setcfact, {.f = +0.25} } },
  { LAYOUT, { MOD_CONTROL|MOD_SHIFT, Key_Up, setcfact, {.f = 0} } },
  // Change layout
  EXIT_TO_NORMAL_MODE(LAYOUT, MOD_NONE, Key_1, setsize, {.v = &sizes[0]}),
  EXIT_TO_NORMAL_MODE(LAYOUT, MOD_NONE, Key_2, setminsize, {0}),
  EXIT_TO_NORMAL_MODE(LAYOUT, MOD_NONE, Key_3, setmaxsize, {0}),
  EXIT_TO_NORMAL_MODE(LAYOUT, MOD_NONE, Key_t, setlayout, {.v = &layouts[LAYOUT_TILE]}),
  EXIT_TO_NORMAL_MODE(LAYOUT, MOD_NONE, Key_f, setlayout, {.v = &layouts[LAYOUT_BSTACK]}),
  EXIT_TO_NORMAL_MODE(LAYOUT, MOD_SHIFT, Key_f, setlayout, {.v = &layouts[LAYOUT_FLOAT]}),
  EXIT_TO_NORMAL_MODE(LAYOUT, MOD_NONE, Key_m, setlayout, {.v = &layouts[LAYOUT_MONOCLE]}),
  { LAYOUT, { MOD_NONE, Key_Escape, entermode, {.i = NORMAL} } },

  // Open Browser
  EXIT_TO_NORMAL_MODE(BROWSER, MOD_NONE, Key_f, spawn, SHCMD_UWSM("firefox")),
  EXIT_TO_NORMAL_MODE(BROWSER, MOD_NONE, Key_b, spawn, SHCMD_UWSM("brave")),
  EXIT_TO_NORMAL_MODE(BROWSER, MOD_NONE, Key_g, spawn, SHCMD_UWSM("google-chrome-stable")),
  EXIT_TO_NORMAL_MODE(BROWSER, MOD_NONE, Key_m, spawn, SHCMD_UWSM("microsoft-edge")),
  EXIT_TO_NORMAL_MODE(BROWSER, MOD_SHIFT, Key_i, raiserunnamedscratchpad, SHCMD_UWSM_SK("g", "microsoft-edge --profile-directory=Default --app=https://www.bing.com/chat")),
  EXIT_TO_NORMAL_MODE(BROWSER, MOD_NONE, Key_i, raiserunnamedscratchpad, SHCMD_UWSM_SK("c", "google-chrome-stable --profile-directory=Default --app=https://chat.openai.com")),
  EXIT_TO_NORMAL_MODE(BROWSER, MOD_NONE, Key_o, raiserunnamedscratchpad, SHCMD_UWSM_SK("o", "google-chrome-stable --profile-directory=Default --app=https://ollama.wochap.local")),
  EXIT_TO_NORMAL_MODE(BROWSER, MOD_NONE, Key_w, raiserunnamedscratchpad, SHCMD_UWSM_SK("w", "google-chrome-stable --profile-directory=Default --app=https://openwebui.wochap.local")),
  EXIT_TO_NORMAL_MODE(BROWSER, MOD_NONE, Key_u, raiserunnamedscratchpad, SHCMD_UWSM_SK("y", "google-chrome-stable --profile-directory=Default --app=https://music.youtube.com")),
  { BROWSER, { MOD_NONE, Key_Escape, entermode, {.i = NORMAL} } },

  // Terminal TUI
  EXIT_TO_NORMAL_MODE(TUI, MOD_NONE, Key_n, raiserunnamedscratchpad, SHCMD_UWSM_SK("n", "tui-notes")),
  EXIT_TO_NORMAL_MODE(TUI, MOD_NONE, Key_i, raiserunnamedscratchpad, SHCMD_UWSM_SK("b", "tui-notes-obsidian")),
  EXIT_TO_NORMAL_MODE(TUI, MOD_NONE, Key_m, raiserunnamedscratchpad, SHCMD_UWSM_SK("m", "tui-monitor")),
  EXIT_TO_NORMAL_MODE(TUI, MOD_NONE, Key_e, raiserunnamedscratchpad, SHCMD_UWSM_SK("e", "tui-email")),
  EXIT_TO_NORMAL_MODE(TUI, MOD_NONE, Key_r, raiserunnamedscratchpad, SHCMD_UWSM_SK("r", "tui-rss")),
  EXIT_TO_NORMAL_MODE(TUI, MOD_NONE, Key_u, raiserunnamedscratchpad, SHCMD_UWSM_SK("u", "tui-music")),
  EXIT_TO_NORMAL_MODE(TUI, MOD_NONE, Key_d, raiserunnamedscratchpad, SHCMD_UWSM_SK("d", "tui-notification-center")),
  EXIT_TO_NORMAL_MODE(TUI, MOD_NONE, Key_c, raiserunnamedscratchpad, SHCMD_UWSM_SK("k", "tui-calendar")),
  EXIT_TO_NORMAL_MODE(TUI, MOD_NONE, Key_b, spawn, SHCMD_UWSM("tui-bookmarks --select")),
  EXIT_TO_NORMAL_MODE(TUI, MOD_SHIFT, Key_b, spawn, SHCMD_UWSM("tui-bookmarks --add")),
  EXIT_TO_NORMAL_MODE(TUI, MOD_CONTROL|MOD_SHIFT, Key_b, spawn, SHCMD_UWSM("tui-bookmarks --edit")),
  { TUI, { MOD_NONE, Key_Escape, entermode, {.i = NORMAL} } },

  // Notification
  // Show recent notification menu
  EXIT_TO_NORMAL_MODE(NOTIFICATION, MOD_NONE, Key_a, spawn, SHCMD("dunstctl context")),
  // Show last notification
  EXIT_TO_NORMAL_MODE(NOTIFICATION, MOD_NONE, Key_h, spawn, SHCMD("dunstctl history-pop")),
  // Hide recent notification
  EXIT_TO_NORMAL_MODE(NOTIFICATION, MOD_NONE, Key_c, spawn, SHCMD("dunstctl close")),
  // Hide all notifications
  EXIT_TO_NORMAL_MODE(NOTIFICATION, MOD_SHIFT, Key_c, spawn, SHCMD("dunstctl close-all")),
  { NOTIFICATION, { MOD_NONE, Key_Escape, entermode, {.i = NORMAL} } },

  // HACK: disable all dwl keymappings
  { KB_INHIBIT, { MODKEY|MOD_ALT|MOD_CONTROL, Key_g, entermode, {.i = NORMAL} } },
};

static const Button buttons[] = {
	{ MODKEY, BTN_LEFT, moveresize, {.ui = CurMove} },
	{ MODKEY, BTN_MIDDLE, togglefloating, {0} },
	{ MODKEY, BTN_RIGHT, moveresize, {.ui = CurResize} },
	{ MOD_NONE, BTN_EXTRA, shiftview, {.i = 1} },
	{ MOD_NONE, BTN_SIDE, shiftview, {.i = -1} },
	{ MODKEY, BTN_EXTRA, rotatetags, {.i = 1} },
	{ MODKEY, BTN_SIDE, rotatetags, {.i = -1} },
};

static const Gesture gestures[] = {
	{ MODKEY, SWIPE_LEFT, 3, rotatetags, { .i = 1 } },
	{ MODKEY, SWIPE_RIGHT, 3, rotatetags, { .i = -1 } },
	{ MOD_NONE, SWIPE_LEFT, 3, shiftview, { .i = 1 } },
	{ MOD_NONE, SWIPE_RIGHT, 3, shiftview, { .i = -1 } },
	{ MOD_NONE, SWIPE_DOWN, 3, focusstack, {.i = 1} },
	{ MOD_NONE, SWIPE_UP, 3, focusstack, {.i = -1} },
};

