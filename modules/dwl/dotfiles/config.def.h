#define RGB(col) { \
	((col >> 16) & 0xff) / 255.0f, \
	((col >> 8) & 0xff) / 255.0f, \
	(col & 0xff) / 255.0f, \
	1.0f \
}

/* appearance */
static const int sloppyfocus               = 1;  /* focus follows mouse */
static const int bypass_surface_visibility = 0;  /* 1 means idle inhibitors will disable idle tracking even if it's surface isn't visible  */
static const unsigned int borderpx         = 2;  /* border pixel of windows */
/* To conform the xdg-protocol, set the alpha to zero to restore the old behavior */
static const float fullscreen_bg[]         = {0.1, 0.1, 0.1, 0};
static const unsigned int swipe_min_threshold = 0;
static const int swipe_fingers_count       = 3;
static const int center_relative_to_monitor = 1;  /* 0 means center floating relative to the window area  */

enum {
	BROWSER,
	LAYOUT,
	TUI,
};
const char *modes_labels[] = {
	"browser",
	"layout",
	"tui",
};

/* Autostart */
static const char *const autostart[] = {
  "restart-pipewire-and-portal-services", NULL,
  "configure-gtk", NULL,

  // start systemd services related to graphical-session.target
  // https://github.com/emersion/xdg-desktop-portal-wlr/wiki/systemd-user-services,-pam,-and-environment-variables
  "sh", "-c", "systemctl --user start graphical-session.target", NULL,

  "sh", "-c", "/etc/scripts/dwl-autostart.sh", NULL,
  NULL /* terminate */
};

/* tagging - tagcount must be no greater than 31 */
#define TAGCOUNT (9)
static const int tagcount = TAGCOUNT;

static const Rule rules[] = {
	/* app_id                    title       tags mask  isfloating  monitor  x    y    width height  scratchkey isterm  noswallow */
	/* examples:
	{ "Gimp",                    NULL,       0,         1,          -1, 	   0, 	0,   500,  400,    0,         0,      0 },
	*/
	{ "file-roller",             NULL,       0,         1,          -1,      0,   0,   0,    0,      0,         0,      0 },
	{ "gnome-font-viewer",       NULL,       0,         1,          -1,      0,   0,   0,    0,      0,         0,      0 },
	{ "gnome-system-monitor",    NULL,       0,         1,          -1,      0,   0,   0,    0,      0,         0,      0 },
	{ "mpv",                     NULL,       0,         1,          -1,      0,   0,   0,    0,      0,         0,      0 },
	{ "imv",                     NULL,       0,         1,          -1,      0,   0,   0,    0,      0,         0,      0 },
	{ "org.gnome.Calculator",    NULL,       0,         1,          -1,      0,   0,   0,    0,      0,         0,      0 },
	{ "pavucontrol",             NULL,       0,         1,          -1,      0,   0,   0,    0,      0,         0,      0 },
	{ "^thunar$",                NULL,       0,         1,          -1,      0,   0,   0,    0,      0,         0,      -1 },
	{ "^thunar-scratch$",        NULL,       0,         1,          -1,      0,   0,   0,    0,      'f',       0,      -1 },
	{ "xdg-desktop-portal-gtk",  NULL,       0,         1,          -1,      0,   0,   0,    0,      0,         0,      0 },
	{ "org.qutebrowser.qutebrowser", NULL,   0,         0,          -1,      0,   0,   0,    0,      0,         0,      -1 },
	{ NULL, "meet.google.com is sharing your screen.", 0, 1,        -1,      0,   0,   0,    0,      0,         0,      0 },

	{ "firefox",                 NULL,       1 << 4,    0,          -1,      0,   0,   0,    0,      0,         0,      0 },
	{ "google-chrome",           NULL,       1 << 0,    0,          -1,      0,   0,   0,    0,      0,         0,      0 },
	{ "brave-browser",           NULL,       1 << 7,    0,          -1,      0,   0,   0,    0,      0,         0,      0 },
	{ "Slack",                   NULL,       1 << 3,    0,          -1,      0,   0,   0,    0,      0,         0,      0 },

	{ "kitty-top",               NULL,       0,         1,          -1,      0,   0,   1200, 800,    'm',       0,      0 },
	{ "kitty-scratch",           NULL,       0,         1,          -1,      0,   0,   1200, 800,    'i',       0,      0 },
	{ "kitty-neorg",             NULL,       0,         1,          -1,      0,   0,   1200, 800,    'n',       0,      0 },
	{ "kitty-nmtui",             NULL,       0,         1,          -1,      0,   0,   1200, 800,    'w',       0,      0 },
	{ "kitty-neomutt",           NULL,       0,         1,          -1,      0,   0,   1200, 800,    'e',       0,      0 },
	{ "kitty-newsboat",          NULL,       0,         1,          -1,      0,   0,   1200, 800,    'r',       0,      0 },
	{ "kitty-ncmpcpp",           NULL,       0,         1,          -1,      0,   0,   1200, 800,    'u',       0,      0 },

	{ "^kitty-dangerp$",         NULL,       1 << 1,    0,          -1,      0,   0,   0,    0,      0,         0,      0 },
	{ "^Alacritty$",             NULL,       0,         0,          -1,      0,   0,   0,    0,      0,         1,      0 },
	{ "^kitty$",                 NULL,       0,         0,          -1,      0,   0,   0,    0,      0,         1,      0 },

	/* x, y, width, heigh are floating only
	* When x or y == 0 the client is placed at the center of the screen,
	* when width or height == 0 the default size of the client is used*/
};

/* layout(s) */
static const Layout layouts[] = {
	/* symbol     arrange function */
	{ "[]=",      tile },
	{ "><>",      NULL },    /* no layout function means floating behavior */
	{ "[M]",      monocle },
	{ "|M|",      centeredmaster },
	{ "||",       column },
  { "HHH",      grid },
	{ "[@]",      spiral },
	{ "@|@",      snail },
	{ "[\\]",     dwindle },
	{ NULL,       NULL },
};

enum layout_types {
  LAYOUT_TILE,
  LAYOUT_FLOAT,
  LAYOUT_MONOCLE,
  LAYOUT_CENTEREDMASTER,
  LAYOUT_COLUMN,
  LAYOUT_GRID,
  LAYOUT_SPIRAL,
  LAYOUT_SNAIL,
  LAYOUT_DWINDLE,
};

/* monitors */
static const MonitorRule monrules[] = {
	/* name       mfact nmaster scale layout       rotate/reflect                x    y */
	/* example of a HiDPI laptop monitor:
	{ "eDP-1",    0.5,  1,      2,    &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL,   -1,  -1 },
	*/
  { "DP-1",     0.5, 1,      1,    &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL,   -1,  -1 },
  { "eDP-1",    0.5, 1,      2,    &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL,   -1,  -1 },
	/* defaults */
	{ NULL,       0.6, 1,      1,    &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL,   -1,  -1 },
};

/* keyboard */
static const struct xkb_rule_names xkb_rules = {
	/* can specify fields: rules, model, layout, variant, options */
	/* example:
	.options = "ctrl:nocaps",
	*/
  .layout = "us",
	.options = NULL,
};

static const int repeat_rate = 50;
static const int repeat_delay = 300;

/* Trackpad */
static const int tap_to_click = 0;
static const int tap_and_drag = 0;
static const int drag_lock = 1;
static const int natural_scrolling = 1;
static const int disable_while_typing = 1;
static const int left_handed = 0;
static const int middle_button_emulation = 0;
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
static const char *termcmd[] = { "kitty", NULL };
static const char *menucmd[] = { "tofi-launcher", NULL };

#include "shiftview.c"

/* named scratchpads - First arg only serves to match against key in rules*/
static const char *fmscratchcmd[] = { "f", "thunar", "--name", "thunar-scratch", NULL };
static const char *kittytopcmd[] = { "m", "bash", "-c", "~/.config/kitty/scripts/kitty-top.sh", NULL };
static const char *kittyscratchcmd[] = { "i", "bash", "-c", "~/.config/kitty/scripts/kitty-scratch.sh", NULL };
static const char *kittyneorgcmd[] = { "n", "bash", "-c", "~/.config/kitty/scripts/kitty-neorg.sh", NULL };
// static const char *kittynmtuicmd[] = { "w", "bash", "-c", "~/.config/kitty/scripts/kitty-nmtui.sh", NULL };
static const char *kittyneomuttcmd[] = { "e", "bash", "-c", "~/.config/kitty/scripts/kitty-neomutt.sh", NULL };
static const char *kittynewsboatcmd[] = { "r", "bash", "-c", "~/.config/kitty/scripts/kitty-newsboat.sh", NULL };
static const char *kittyncmpcppcmd[] = { "u", "bash", "-c", "~/.config/kitty/scripts/kitty-ncmpcpp.sh", NULL };

#include "keys.h"
static const Key keys[] = {
	/* count key_sequences                                function          argument */


  // ### SYSTEM KEYBINDINGS

  // Open scratchpad terminal
  { MODKEY, Key_i, togglescratch, {.v = kittyscratchcmd } },

  // Lock screen
	{ MODKEY, Key_l, spawn, SHCMD("/etc/scripts/system/sway-lock.sh") },

  // Open power menu
  { MODKEY, Key_Escape, spawn, SHCMD("tofi-powermenu") },

  // Open app launcher
	{ MODKEY, Key_space, spawn, {.v = menucmd} },

  // Take fullscreen screenshoot
  { MODKEY, Key_Print, spawn, SHCMD("/etc/scripts/system/takeshot.sh --now") },

  // Open calc
  { MODKEY, Key_c, spawn, SHCMD("rofi-calc") },

  // Show clipboard
  { MODKEY, Key_v, spawn, SHCMD("/etc/scripts/system/clipboard-manager.sh --menu") },

  // Clear clipboard
  { MODKEY|MOD_SHIFT, Key_v, spawn, SHCMD("/etc/scripts/system/clipboard-manager.sh --clear") },

  // Show emojis
  { MODKEY, Key_e, spawn, SHCMD("rofi-emoji") },

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

  // Toggle visibility of bar?
  // { MODKEY, Key_h, toggle_visibility, {0} },

  // Focus direction
  { MODKEY, Key_n, focusstack, {.i = +1} },
  { MODKEY, Key_p, focusstack, {.i = -1} },

  // Swap direction
  { MODKEY|MOD_SHIFT, Key_n, movestack, {.i = +1} },
  { MODKEY|MOD_SHIFT, Key_p, movestack, {.i = -1} },

  // Resize
  { MODKEY|MOD_ALT|MOD_SHIFT, Key_Down, moveresizekb, {.v = (int []){ 0, 0, 0, 40 }}},
  { MODKEY|MOD_ALT|MOD_SHIFT, Key_Up, moveresizekb, {.v = (int []){ 0, 0, 0, -40 }}},
  { MODKEY|MOD_ALT|MOD_SHIFT, Key_Right, moveresizekb, {.v = (int []){ 0, 0, 40, 0 }}},
  { MODKEY|MOD_ALT|MOD_SHIFT, Key_Left, moveresizekb, {.v = (int []){ 0, 0, -40, 0 }}},

  // Move
  { MODKEY|MOD_ALT, Key_Down, moveresizekb, {.v = (int []){ 0, 40, 0, 0 }}},
  { MODKEY|MOD_ALT, Key_Up, moveresizekb, {.v = (int []){ 0, -40, 0, 0 }}},
  { MODKEY|MOD_ALT, Key_Right, moveresizekb, {.v = (int []){ 40, 0, 0, 0 }}},
  { MODKEY|MOD_ALT, Key_Left, moveresizekb, {.v = (int []){ -40, 0, 0, 0 }}},

  // Focus next/previous monitor
  { MODKEY, Key_comma, focusmon, {.i = WLR_DIRECTION_LEFT} },
  { MODKEY, Key_period, focusmon, {.i = WLR_DIRECTION_RIGHT} },

  // Send focused view to the next/previous monitor
  { MODKEY|MOD_SHIFT, Key_comma, tagmon, {.i = WLR_DIRECTION_LEFT} },
  { MODKEY|MOD_SHIFT, Key_period, tagmon, {.i = WLR_DIRECTION_RIGHT} },

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
	{ MODKEY|MOD_ALT, Key_t, spawn, {.v = termcmd} },

  // Open file manager
  { MODKEY|MOD_ALT, Key_f, togglescratch, {.v = fmscratchcmd} },

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

  { LAYOUT, { MOD_NONE, Key_c, movecenter, {0} } },
  { LAYOUT, { MOD_NONE, Key_c, entermode, {.i = NORMAL} } },
  // Toggle gaps
  // { LAYOUT, { MOD_NONE, Key_grave, togglegaps, {0} } },
  // { LAYOUT, { MOD_NONE, Key_grave, entermode, {.i = NORMAL} } },
  // To decrease/increase the main count
  { LAYOUT, { MOD_NONE, Key_Left, incnmaster, {.i = +1} } },
  { LAYOUT, { MOD_NONE, Key_Right, incnmaster, {.i = -1} } },
  // To increment/decrement the main ratio
  { LAYOUT, { MOD_NONE, Key_Up, setmfact, {.f = +0.05} } },
  { LAYOUT, { MOD_NONE, Key_Down, setmfact, {.f = -0.05} } },
  // Change layout
  { LAYOUT, { MOD_NONE, Key_comma, cyclelayout, {.i = -1 } } },
  { LAYOUT, { MOD_NONE, Key_period, cyclelayout, {.i = +1 } } },
  { LAYOUT, { MOD_NONE, Key_1, setlayout, {.v = &layouts[LAYOUT_TILE]} } },
  { LAYOUT, { MOD_NONE, Key_2, setlayout, {.v = &layouts[LAYOUT_FLOAT]} } },
  { LAYOUT, { MOD_NONE, Key_3, setlayout, {.v = &layouts[LAYOUT_MONOCLE]} } },
  { LAYOUT, { MOD_NONE, Key_4, setlayout, {.v = &layouts[LAYOUT_CENTEREDMASTER]} } },
  { LAYOUT, { MOD_NONE, Key_5, setlayout, {.v = &layouts[LAYOUT_COLUMN]} } },
  { LAYOUT, { MOD_NONE, Key_6, setlayout, {.v = &layouts[LAYOUT_GRID]} } },
  { LAYOUT, { MOD_NONE, Key_7, setlayout, {.v = &layouts[LAYOUT_SPIRAL]} } },
  { LAYOUT, { MOD_NONE, Key_8, setlayout, {.v = &layouts[LAYOUT_SNAIL]} } },
  { LAYOUT, { MOD_NONE, Key_9, setlayout, {.v = &layouts[LAYOUT_DWINDLE]} } },
  { LAYOUT, { MOD_NONE, Key_Escape, entermode, {.i = NORMAL} } },

  // Open Browser
  { BROWSER, { MOD_NONE, Key_f, spawn, RUN("firefox") } },
  { BROWSER, { MOD_NONE, Key_f, entermode, {.i = NORMAL} } },
  { BROWSER, { MOD_NONE, Key_b, spawn, RUN("brave") } },
  { BROWSER, { MOD_NONE, Key_b, entermode, {.i = NORMAL} } },
  { BROWSER, { MOD_NONE, Key_g, spawn, RUN("google-chrome-stable") } },
  { BROWSER, { MOD_NONE, Key_g, entermode, {.i = NORMAL} } },
  { BROWSER, { MOD_NONE, Key_Escape, entermode, {.i = NORMAL} } },

  // Terminal TUI
  { TUI, { MOD_NONE, Key_n, togglescratch, {.v = kittyneorgcmd} } },
  { TUI, { MOD_NONE, Key_n, entermode, {.i = NORMAL} } },
  { TUI, { MOD_NONE, Key_m, togglescratch, {.v = kittytopcmd} } },
  { TUI, { MOD_NONE, Key_m, entermode, {.i = NORMAL} } },
  { TUI, { MOD_NONE, Key_e, togglescratch, {.v = kittyneomuttcmd} } },
  { TUI, { MOD_NONE, Key_e, entermode, {.i = NORMAL} } },
  { TUI, { MOD_NONE, Key_r, togglescratch, {.v = kittynewsboatcmd} } },
  { TUI, { MOD_NONE, Key_r, entermode, {.i = NORMAL} } },
  { TUI, { MOD_NONE, Key_u, togglescratch, {.v = kittyncmpcppcmd} } },
  { TUI, { MOD_NONE, Key_u, entermode, {.i = NORMAL} } },
  { TUI, { MOD_NONE, Key_Escape, entermode, {.i = NORMAL} } },
};

static const Button buttons[] = {
	{ MODKEY, BTN_LEFT,   moveresize,     {.ui = CurMove} },
	{ MODKEY, BTN_MIDDLE, togglefloating, {0} },
	{ MODKEY, BTN_RIGHT,  moveresize,     {.ui = CurResize} },
};

static const Gesture gestures[] = {
	{ SWIPE_LEFT, shiftview, { .i = 1 } },
	{ SWIPE_RIGHT, shiftview, { .i = -1 } },
};

