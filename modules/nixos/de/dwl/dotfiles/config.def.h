/* Taken from https://github.com/djpohly/dwl/issues/466 */
#define COLOR(hex) { \
	((hex >> 24) & 0xFF) / 255.0f, \
	((hex >> 16) & 0xFF) / 255.0f, \
	((hex >> 8) & 0xFF) / 255.0f, \
	(hex & 0xFF) / 255.0f \
}

/* appearance */
static const int sloppyfocus               = 1;  /* focus follows mouse */
static const int bypass_surface_visibility = 0;  /* 1 means idle inhibitors will disable idle tracking even if it's surface isn't visible  */
static const unsigned int borderpx         = 2;  /* border pixel of windows */
static const unsigned int borderspx        = 0;  /* border pixel of windows */
static const unsigned int borderepx        = 1;  /* border pixel of windows */
static const unsigned int borderspx_offset = 0;  /* border pixel of windows */
static const unsigned int borderepx_negative_offset = 0;  /* border pixel of windows */
static const int draw_minimal_borders      = 1; /* merge adjacent borders */
static const int border_color_type         = BrdEnd;
/* To conform the xdg-protocol, set the alpha to zero to restore the old behavior */
static const float fullscreen_bg[]         = {0.1, 0.1, 0.1, 1.0};
static const unsigned int swipe_min_threshold = 0;
static const int center_relative_to_monitor = 1;  /* 0 means center floating relative to the window area  */

enum {
	BROWSER,
	LAYOUT,
	TUI,
  KB_INHIBIT,
};
const char *modes_labels[] = {
	"browser",
	"layout",
	"tui",
	"kb inhibit",
};

/* Autostart */
static const char *const autostart[] = {
  "sh", "-c", "dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP SWAYSOCK QT_QPA_PLATFORMTHEME && systemctl --user stop wayland-session.target && systemctl --user start wayland-session.target", NULL,

  "configure-gtk", NULL,

  NULL /* terminate */
};

/* tagging - TAGCOUNT must be no greater than 31 */
#define TAGCOUNT (9)

/* logging */
static int log_level = WLR_ERROR;

/* named scratchpads - First arg only serves to match against key in rules*/
static const char *msgptscratchcmd[] = { "g", "microsoft-edge", "--app=https://www.bing.com/search?q=q&showconv=1", NULL };
static const char *chatgptscratchcmd[] = { "c", "google-chrome-stable", "--app=https://chat.openai.com", NULL };
static const char *ytmusicscratchcmd[] = { "y", "google-chrome-stable", "--app=https://music.youtube.com", NULL };
static const char *fmscratchcmd[] = { "f", "thunar", "--name", "thunar-scratch", NULL };
static const char *kittytopcmd[] = { "m", "sh", "-c", "~/.config/kitty/scripts/kitty-top.sh", NULL };
static const char *kittyscratchcmd[] = { "i", "sh", "-c", "~/.config/kitty/scripts/kitty-scratch.sh", NULL };
static const char *kittyneorgcmd[] = { "n", "sh", "-c", "~/.config/kitty/scripts/kitty-neorg.sh", NULL };
// static const char *kittynmtuicmd[] = { "w", "sh", "-c", "~/.config/kitty/scripts/kitty-nmtui.sh", NULL };
static const char *kittyneomuttcmd[] = { "e", "sh", "-c", "~/.config/kitty/scripts/kitty-neomutt.sh", NULL };
static const char *kittynewsboatcmd[] = { "r", "sh", "-c", "~/.config/kitty/scripts/kitty-newsboat.sh", NULL };
static const char *kittyncmpcppcmd[] = { "u", "sh", "-c", "~/.config/kitty/scripts/kitty-ncmpcpp.sh", NULL };

static const char bing_gpt_appid[] = "msedge-www.bing.com__search-Default";
static const char chat_gpt_appid[] = "chrome-chat.openai.com__-Default";
static const char ytmusic_appid[] = "chrome-music.youtube.com__-Default";

static const Rule rules[] = {
	/* app_id                    title       tags mask  isfloating  monitor  x    y    width height  scratchkey */
	/* examples:
	{ "Gimp",                    NULL,       0,         1,          -1, 	   0, 	0,   500,  400,    0 },
	*/
	{ "file-roller",             NULL,       0,         1,          -1,      0,   0,   0,    0,      0 },
	{ "gnome-font-viewer",       NULL,       0,         1,          -1,      0,   0,   0,    0,      0 },
	{ "gnome-system-monitor",    NULL,       0,         1,          -1,      0,   0,   0,    0,      0 },
	{ "mpv",                     NULL,       0,         1,          -1,      0,   0,   0,    0,      0 },
	{ "imv",                     NULL,       0,         1,          -1,      0,   0,   0,    0,      0 },
	{ "org.gnome.Calculator",    NULL,       0,         1,          -1,      0,   0,   0,    0,      0 },
	{ "pavucontrol",             NULL,       0,         1,          -1,      0,   0,   0,    0,      0 },
	{ "^thunar$",                NULL,       0,         1,          -1,      0,   0,   0,    0,      0 },
	{ "^thunar-scratch$",        NULL,       0,         1,          -1,      0,   0,   0,    0,      'f' },
	{ "xdg-desktop-portal-gtk",  NULL,       0,         1,          -1,      0,   0,   0,    0,      0 },
	{ "org.qutebrowser.qutebrowser", NULL,   0,         0,          -1,      0,   0,   0,    0,      0 },
	{ NULL, "meet.google.com is sharing your screen.", 0, 1,        -1,      0,   0,   0,    0,      0 },
	{ bing_gpt_appid,            NULL,       0,         1,          -1,      0,   0,   1200, 800,    'g' },
	{ chat_gpt_appid,            NULL,       0,         1,          -1,      0,   0,   1200, 800,    'c' },
	{ ytmusic_appid,             NULL,       0,         1,          -1,      0,   0,   1200, 800,    'y' },

	{ "firefox",                 NULL,       1 << 4,    0,          -1,      0,   0,   0,    0,      0 },
	{ "google-chrome",           NULL,       1 << 0,    0,          -1,      0,   0,   0,    0,      0 },
	{ "brave-browser",           NULL,       1 << 7,    0,          -1,      0,   0,   0,    0,      0 },
	{ "Slack",                   NULL,       1 << 3,    0,          -1,      0,   0,   0,    0,      0 },
	{ "discord",                 NULL,       1 << 3,    0,          -1,      0,   0,   0,    0,      0 },
	{ "microsoft-edge",          NULL,       1 << 8,    0,          -1,      0,   0,   0,    0,      0 },

	{ "kitty-top",               NULL,       0,         1,          -1,      0,   0,   1200, 800,    'm' },
	{ "kitty-scratch",           NULL,       0,         1,          -1,      0,   0,   1200, 800,    'i' },
	{ "kitty-neorg",             NULL,       0,         1,          -1,      0,   0,   1200, 800,    'n' },
	{ "kitty-nmtui",             NULL,       0,         1,          -1,      0,   0,   1200, 800,    'w' },
	{ "kitty-neomutt",           NULL,       0,         1,          -1,      0,   0,   1200, 800,    'e' },
	{ "kitty-newsboat",          NULL,       0,         1,          -1,      0,   0,   1200, 800,    'r' },
	{ "kitty-ncmpcpp",           NULL,       0,         1,          -1,      0,   0,   1200, 800,    'u' },
	{ "kitty-buku",              NULL,       0,         1,          -1,      0,   0,   1200, 800,    0 },

	{ "^kitty-dangerp$",         NULL,       1 << 1,    0,          -1,      0,   0,   0,    0,      0 },
	{ "^Alacritty$",             NULL,       0,         0,          -1,      0,   0,   0,    0,      0 },
	{ "^kitty$",                 NULL,       0,         0,          -1,      0,   0,   0,    0,      0 },

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
	{ "|M|",      centeredmaster },
	// { "@|@",      snail },
	{ "><>",      NULL },    /* no layout function means floating behavior */
	{ NULL,       NULL },
};

enum layout_types {
  LAYOUT_TILE,
  LAYOUT_BSTACK,
  LAYOUT_MONOCLE,
  LAYOUT_CENTEREDMASTER,
  // LAYOUT_SNAIL,
  LAYOUT_FLOAT,
};

/* monitors */
static const MonitorRule monrules[] = {
	/* name       mfact nmaster scale layout       rotate/reflect                x    y */
	/* example of a HiDPI laptop monitor:
	{ "eDP-1",    0.5,  1,      2,    &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL,   -1,  -1 },
	*/
  // { "DP-1",     0.5, 1,      1,    &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL,   -1,  -1 },
  // { "eDP-1",    0.5, 1,      2,    &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL,   -1,  -1 },
	/* defaults */
	{ NULL,       0.5, 1,      2,    &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL,   -1,  -1 },
};

/* keyboard */
static const struct xkb_rule_names xkb_rules = {
	/* can specify fields: rules, model, layout, variant, options */
	/* example:
	.options = "ctrl:nocaps",
	*/
	.options = NULL,
};

static const int repeat_rate = 50;
static const int repeat_delay = 300;

/* gb will be set the first time togglekblayout is called, then us.. it is
 * recommended to set the same layout in position 0 of kblayouts and in
 * xkb_rules */
static const char *kblayouts[] = {"us", "ru"};

/* Trackpad */
static const int tap_to_click = 1;
static const int tap_and_drag = 0;
static const int drag_lock = 0;
static const int natural_scrolling = 1;
static const int disable_while_typing = 1;
static const int left_handed = 0;
static const int middle_button_emulation = 1;
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
static const double accel_speed = 0.0;
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

#define TAGKEYS(KEY,TAG) \
	{ MODKEY,  KEY,                      view,       {.ui = 1 << TAG} }, \
	{ MODKEY|MOD_CONTROL, KEY,           toggleview, {.ui = 1 << TAG} }, \
	{ MODKEY|MOD_SHIFT, KEY,             tag,        {.ui = 1 << TAG} }, \
	{ MODKEY|MOD_CONTROL|MOD_SHIFT, KEY, toggletag,  {.ui = 1 << TAG} }

/* helper for spawning shell commands in the pre dwm-5.0 fashion */
#define SHCMD(cmd) { .v = (const char*[]){ "sh", "-c", cmd, NULL } }

/* commands */
#define RUN(...)   { .v = (const char*[]){ __VA_ARGS__, NULL } }

#include "shiftview.c"

#include "keys.h"
static const Key keys[] = {
	/* count key_sequences                                function          argument */


  // ### SYSTEM KEYBINDINGS

  // Open scratchpad terminal
  { MODKEY, Key_i, focusortogglescratch, {.v = kittyscratchcmd } },

  // Lock screen
	{ MODKEY, Key_l, spawn, SHCMD("/etc/scripts/system/sway-lock.sh") },

  // Open power menu
  { MODKEY, Key_Escape, spawn, SHCMD("tofi-powermenu") },

  // Open app launcher
	{ MODKEY, Key_space, spawn, SHCMD("tofi-launcher") },

  // Take fullscreen screenshoot
  { MODKEY, Key_Print, spawn, SHCMD("/etc/scripts/system/takeshot.sh --now") },

  // Open calc
  { MODKEY, Key_c, spawn, SHCMD("tofi-calc") },

  // Show clipboard
  { MODKEY, Key_v, spawn, SHCMD("/etc/scripts/system/clipboard-manager.sh --menu") },

  // Clear clipboard
  { MODKEY|MOD_SHIFT, Key_v, spawn, SHCMD("/etc/scripts/system/clipboard-manager.sh --clear") },

  // Show emojis
  { MODKEY, Key_e, spawn, SHCMD("tofi-emoji") },

  // Show last notification
  { MODKEY|MOD_CONTROL, Key_n, spawn, SHCMD("dunstctl history-pop") },

  // Hide recent notification
  { MODKEY|MOD_CONTROL|MOD_SHIFT, Key_n, spawn, SHCMD("dunstctl close") },

  // Hide all notifications
  { MODKEY|MOD_CONTROL|MOD_SHIFT, Key_Escape, spawn, SHCMD("dunstctl close-all") },

  // Toggle bar
  { MODKEY, Key_b, spawn, SHCMD("/etc/scripts/waybar/waybar-toggle.sh") },


  // ### WM KEYBINDINGS

  // Close focused view
  { MODKEY|MOD_SHIFT, Key_w, killclient, {0} },

  // Toggle float
  { MODKEY, Key_s, togglefloating, {0} },

  // Toggle fullscreen
  { MODKEY, Key_f, togglefullscreen, {0} },

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
  { MODKEY, Key_comma, rotatetags, {.i = -1} },
  { MODKEY, Key_period, rotatetags, {.i = 1} },

  // Send focused view to the next/previous tag
  { MODKEY|MOD_SHIFT, Key_comma, rotatetags, {.i = -2} },
  { MODKEY|MOD_SHIFT, Key_period, rotatetags, {.i = 2} },

  // Bump focused view to the top of the layout stack
  { MODKEY, Key_Return, zoom, {0} },


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

  // Set sticky
  { MODKEY|MOD_CONTROL, Key_y, tag, {.ui = ~0} },

  // Focus previous tags
  { MODKEY, Key_grave, view, {0} },

  // Focus all tags
  { MODKEY, Key_0, view, {.ui = ~0} },


  // ### APPLICATION KEYBINDINGS (Super + Alt + Key)

  // Open primary terminal
	{ MODKEY|MOD_ALT, Key_t, spawn, SHCMD("kitty") },

  // Open file manager
  { MODKEY|MOD_ALT, Key_f, focusortogglescratch, {.v = fmscratchcmd} },

  // Screencast/record region to mp4
  { MODKEY|MOD_ALT, Key_r, spawn, SHCMD("/etc/scripts/system/recorder.sh --area") },

  // Open screenshoot utility
  { MODKEY|MOD_ALT, Key_s, spawn, SHCMD("/etc/scripts/system/takeshot.sh --area") },

  // Open color picker
  { MODKEY|MOD_ALT, Key_c, spawn, SHCMD("/etc/scripts/system/color-picker.sh") },


  // ### MEDIA KEYBINDINGS

  { MOD_NONE, Key_XF86AudioRaiseVolume, spawn, SHCMD("wob-osd --volume +5%") },
  { MOD_NONE, Key_XF86AudioLowerVolume, spawn, SHCMD("wob-osd --volume -5%") },
  { MOD_NONE, Key_XF86AudioMute, spawn, SHCMD("wob-osd --volume-toggle") },

  { MOD_NONE, Key_XF86AudioNext, spawn, SHCMD("playerctl next") },
  { MOD_NONE, Key_XF86AudioPrev, spawn, SHCMD("playerctl previous") },
  { MOD_NONE, Key_XF86AudioStop, spawn, SHCMD("playerctl pause") },
  { MOD_NONE, Key_XF86AudioPlay, spawn, SHCMD("playerctl play-pause") },

  { MOD_NONE, Key_XF86MonBrightnessUp, spawn, SHCMD("wob-osd --backlight 5%+") },
  { MOD_NONE, Key_XF86MonBrightnessDown, spawn, SHCMD("wob-osd --backlight 5%-") },

  { MOD_NONE, Key_XF86KbdBrightnessUp, spawn, SHCMD("wob-osd --kbd-backlight 5%+") },
  { MOD_NONE, Key_XF86KbdBrightnessDown, spawn, SHCMD("wob-osd --kbd-backlight 5%-") },


  // ### OTHERS

  { MODKEY, Key_r, entermode, {.i = LAYOUT} },
  { MODKEY|MOD_ALT, Key_b, entermode, {.i = BROWSER} },
  { MODKEY|MOD_ALT, Key_u, entermode, {.i = TUI} },
  { MODKEY|MOD_ALT|MOD_CONTROL, Key_g, entermode, {.i = KB_INHIBIT} },
  { MODKEY|MOD_CONTROL|MOD_SHIFT, Key_w, togglekblayout, {0} },
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

  { MODKEY|MOD_CONTROL|MOD_SHIFT, Key_w, togglekblayout, {0} },
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
  { LAYOUT, { MOD_SHIFT, Key_Left, setmfact, {.f = -0.05} } },
  { LAYOUT, { MOD_SHIFT, Key_Right, setmfact, {.f = +0.05} } },
  // To increment/decrement the client ratio
  { LAYOUT, { MOD_CONTROL|MOD_SHIFT, Key_Left, setcfact, {.f = -0.25} } },
  { LAYOUT, { MOD_CONTROL|MOD_SHIFT, Key_Right, setcfact, {.f = +0.25} } },
  { LAYOUT, { MOD_CONTROL|MOD_SHIFT, Key_Up, setcfact, {.f = 0} } },
  // Change layout
  EXIT_TO_NORMAL_MODE(LAYOUT, MOD_NONE, Key_1, setlayout, {.v = &layouts[LAYOUT_TILE]}),
  EXIT_TO_NORMAL_MODE(LAYOUT, MOD_NONE, Key_2, setlayout, {.v = &layouts[LAYOUT_BSTACK]}),
  EXIT_TO_NORMAL_MODE(LAYOUT, MOD_NONE, Key_3, setlayout, {.v = &layouts[LAYOUT_MONOCLE]}),
  // EXIT_TO_NORMAL_MODE(LAYOUT, MOD_NONE, Key_4, setlayout, {.v = &layouts[LAYOUT_SNAIL]}),
  EXIT_TO_NORMAL_MODE(LAYOUT, MOD_NONE, Key_5, setlayout, {.v = &layouts[LAYOUT_CENTEREDMASTER]}),
  EXIT_TO_NORMAL_MODE(LAYOUT, MOD_NONE, Key_6, setlayout, {.v = &layouts[LAYOUT_FLOAT]}),
  EXIT_TO_NORMAL_MODE(LAYOUT, MOD_NONE, Key_t, setlayout, {.v = &layouts[LAYOUT_TILE]}),
  EXIT_TO_NORMAL_MODE(LAYOUT, MOD_NONE, Key_f, setlayout, {.v = &layouts[LAYOUT_BSTACK]}),
  EXIT_TO_NORMAL_MODE(LAYOUT, MOD_NONE, Key_m, setlayout, {.v = &layouts[LAYOUT_MONOCLE]}),
  // EXIT_TO_NORMAL_MODE(LAYOUT, MOD_NONE, Key_s, setlayout, {.v = &layouts[LAYOUT_SNAIL]}),
  EXIT_TO_NORMAL_MODE(LAYOUT, MOD_NONE, Key_e, setlayout, {.v = &layouts[LAYOUT_CENTEREDMASTER]}),
  { LAYOUT, { MOD_NONE, Key_Escape, entermode, {.i = NORMAL} } },

  // Open Browser
  EXIT_TO_NORMAL_MODE(BROWSER, MOD_NONE, Key_f, spawn, RUN("firefox")),
  EXIT_TO_NORMAL_MODE(BROWSER, MOD_NONE, Key_b, spawn, RUN("brave")),
  EXIT_TO_NORMAL_MODE(BROWSER, MOD_NONE, Key_g, spawn, RUN("google-chrome-stable")),
  EXIT_TO_NORMAL_MODE(BROWSER, MOD_NONE, Key_m, spawn, RUN("microsoft-edge")),
  EXIT_TO_NORMAL_MODE(BROWSER, MOD_NONE, Key_i, focusortogglescratch, {.v = msgptscratchcmd}),
  EXIT_TO_NORMAL_MODE(BROWSER, MOD_SHIFT, Key_i, focusortogglescratch, {.v = chatgptscratchcmd}),
  EXIT_TO_NORMAL_MODE(BROWSER, MOD_NONE, Key_u, focusortogglescratch, {.v = ytmusicscratchcmd}),
  { BROWSER, { MOD_NONE, Key_Escape, entermode, {.i = NORMAL} } },

  // HACK: disable all dwl keymappings
  { KB_INHIBIT, { MODKEY|MOD_ALT|MOD_CONTROL, Key_g, entermode, {.i = NORMAL} } },

  // Terminal TUI
  EXIT_TO_NORMAL_MODE(TUI, MOD_NONE, Key_n, focusortogglescratch, {.v = kittyneorgcmd}),
  EXIT_TO_NORMAL_MODE(TUI, MOD_NONE, Key_m, focusortogglescratch, {.v = kittytopcmd}),
  EXIT_TO_NORMAL_MODE(TUI, MOD_NONE, Key_e, focusortogglescratch, {.v = kittyneomuttcmd}),
  EXIT_TO_NORMAL_MODE(TUI, MOD_NONE, Key_r, focusortogglescratch, {.v = kittynewsboatcmd}),
  EXIT_TO_NORMAL_MODE(TUI, MOD_NONE, Key_u, focusortogglescratch, {.v = kittyncmpcppcmd}),
  EXIT_TO_NORMAL_MODE(TUI, MOD_NONE, Key_b, spawn, SHCMD("~/.config/kitty/scripts/kitty-buku.sh --select")),
  EXIT_TO_NORMAL_MODE(TUI, MOD_SHIFT, Key_b, spawn, SHCMD("~/.config/kitty/scripts/kitty-buku.sh --add")),
  EXIT_TO_NORMAL_MODE(TUI, MOD_CONTROL|MOD_SHIFT, Key_b, spawn, SHCMD("~/.config/kitty/scripts/kitty-buku.sh --edit")),
  { TUI, { MOD_NONE, Key_Escape, entermode, {.i = NORMAL} } },
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
	{ MOD_NONE, SWIPE_DOWN, 3, focusstack, {.i = -1} },
	{ MOD_NONE, SWIPE_UP, 3, focusstack, {.i = 1} },
};

