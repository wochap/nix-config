/* appearance */
static const int sloppyfocus               = 1;  /* focus follows mouse */
static const int bypass_surface_visibility = 0;  /* 1 means idle inhibitors will disable idle tracking even if it's surface isn't visible  */
static const int smartgaps                 = 0;  /* 1 means no outer gap when there is only one window */
static const unsigned int borderpx         = 2;  /* border pixel of windows */
static const unsigned int gappx            = 7; /* horiz inner gap between windows */
static const float bordercolor[]           = {0.68, 0.71, 0.90, 1.0};
static const float focuscolor[]            = {1.0, 0.0, 0.0, 1.0};
static const char cursortheme[]            = "capitaine-cursors"; /* theme from /usr/share/cursors/xorg-x11 */
static const unsigned int cursorsize       = 24;
/* To conform the xdg-protocol, set the alpha to zero to restore the old behavior */
static const float fullscreen_bg[]         = {0.1, 0.1, 0.1, 0};

/* Autostart */
static const char *const autostart[] = {
  "restart-pipewire-and-portal-services", NULL,
  "configure-gtk", NULL,

  // start systemd services related to graphical-session.target
  // https://github.com/emersion/xdg-desktop-portal-wlr/wiki/systemd-user-services,-pam,-and-environment-variables
  "systemctl", "--user", "start", "graphical-session.target", NULL,

  "bash", "/etc/scripts/dwl-autostart.sh", NULL,
  NULL /* terminate */
};

/* tagging - tagcount must be no greater than 31 */
#define TAGCOUNT (9)
static const int tagcount = TAGCOUNT;

static const int hide_type = 1;

#define MENU "rofi -dmenu -config /home/gean/.config/rofi/config-multi-line.rasi"
static const Menu menus[] = {
	/* command                            feed function        action function */
	{ MENU " -i -p Windows",              menuwinfeed,         menuwinaction    },
	{ MENU " -i -p Layouts",              menulayoutfeed,      menulayoutaction },
};

static const Rule rules[] = {
	/* app_id                    title       tags mask  iscentered  isfloating  issticky  monitor  x    y    width height  scratchkey  isterm  noswallow */
	/* examples:
	{ "Gimp",                    NULL,       0,         0,          1,          0,        -1, 	   0, 	0,   500,  400,    0,          0,      0 },
	*/
	{ "file-roller",             NULL,       0,         1,          1,          0,        -1,      0,   0,   0,    0,      0,          0,      0 },
	{ "gnome-font-viewer",       NULL,       0,         1,          1,          0,        -1,      0,   0,   0,    0,      0,          0,      0 },
	{ "gnome-system-monitor",    NULL,       0,         1,          1,          0,        -1,      0,   0,   0,    0,      0,          0,      0 },
	{ "mpv",                     NULL,       0,         1,          1,          0,        -1,      0,   0,   0,    0,      0,          0,      0 },
	{ "org.gnome.Calculator",    NULL,       0,         1,          1,          0,        -1,      0,   0,   0,    0,      0,          0,      0 },
	{ "pavucontrol",             NULL,       0,         1,          1,          0,        -1,      0,   0,   0,    0,      0,          0,      0 },
	{ "thunar",                  NULL,       0,         1,          1,          0,        -1,      0,   0,   0,    0,      0,          0,      0 },
	{ "thunar-scratch",          NULL,       0,         1,          1,          0,        -1,      0,   0,   0,    0,      0,          0,      0 },
	{ "xdg-desktop-portal-gtk",  NULL,       0,         1,          1,          0,        -1,      0,   0,   0,    0,      0,          0,      0 },

	{ "firefox",                 NULL,       1 << 4,    0,          0,          0,        -1,      0,   0,   0,    0,      0,          0,      0 },
	{ "google-chrome",           NULL,       1 << 0,    0,          0,          0,        -1,      0,   0,   0,    0,      0,          0,      0 },
	{ "brave-browser",           NULL,       1 << 7,    0,          0,          0,        -1,      0,   0,   0,    0,      0,          0,      0 },
	{ "Slack",                   NULL,       1 << 3,    0,          0,          0,        -1,      0,   0,   0,    0,      0,          0,      0 },

	{ "kitty-top",               NULL,       0,         1,          1,          0,        -1,      0,   0,   0,    0,      'm',        0,      0 },
	{ "kitty-scratch",           NULL,       0,         1,          1,          0,        -1,      0,   0,   0,    0,      'i',        0,      0 },
	{ "kitty-neorg",             NULL,       0,         1,          1,          0,        -1,      0,   0,   0,    0,      'n',        0,      0 },
	{ "kitty-nmtui",             NULL,       0,         1,          1,          0,        -1,      0,   0,   0,    0,      'w',        0,      0 },
	{ "kitty-neomutt",           NULL,       0,         1,          1,          0,        -1,      0,   0,   0,    0,      'e',        0,      0 },
	{ "kitty-newsboat",          NULL,       0,         1,          1,          0,        -1,      0,   0,   0,    0,      'r',        0,      0 },
	{ "kitty-ncmpcpp",           NULL,       0,         1,          1,          0,        -1,      0,   0,   0,    0,      'u',        0,      0 },

	/* x, y, width, heigh are floating only
	* When x or y == 0 the client is placed at the center of the screen,
	* when width or height == 0 the default size of the client is used*/
};

/* layout(s) */
static const Layout layouts[] = {
	/* symbol     arrange function */
	{ "[]=",      tile },
	{ "><>",      NULL }, /* no layout function means floating behavior */
	{ "[M]",      monocle },
	{ "|M|",      centeredmaster },
	{ "HHH",      grid },
	{ "[@]",      spiral },
	{ "@|@",      snail },
	{ "[\\]",     dwindle },
	{ NULL,       NULL },
};

/* monitors */
static const MonitorRule monrules[] = {
	/* name       mfact nmaster scale layout       rotate/reflect                x    y */
	/* example of a HiDPI laptop monitor:
	{ "eDP-1",    0.5,  1,      2,    &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL,   -1,  -1 },
	*/
  { "eDP-1",    0.64,  1,      2,    &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL,   -1,  -1 },
	/* defaults */
	{ NULL,       0.64, 1,      1,    &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL,   -1,  -1 },
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

/* Prefix key */
#define PREFIXKEY Key_t

#define TAGKEYS(KEY,TAG) \
	{ 1, {{MODKEY,  KEY}},                      view,       {.ui = 1 << TAG} }, \
	{ 1, {{MODKEY|MOD_CONTROL, KEY}},           toggleview, {.ui = 1 << TAG} }, \
	{ 1, {{MODKEY|MOD_SHIFT, KEY}},             tag,        {.ui = 1 << TAG} }, \
	{ 1, {{MODKEY|MOD_CONTROL|MOD_SHIFT, KEY}}, toggletag,  {.ui = 1 << TAG} } 

/* helper for spawning shell commands in the pre dwm-5.0 fashion */
#define SHCMD(cmd) { .v = (const char*[]){ "sh", "-c", cmd, NULL } }

/* commands */
#define RUN(...)   { .v = (const char*[]){ __VA_ARGS__, NULL } }
static const char *termcmd[] = { "kitty", NULL };
static const char *menucmd[] = { "rofi-launcher", NULL };

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
static const Keychord keychords[] = {
	/* Note that Shift changes certain key codes: c -> C, 2 -> at, etc. */
	/* count key_sequences                                function          argument */

  // ### SYSTEM KEYBINDINGS

  // Open scratchpad terminal
  { 1, {{MODKEY, Key_i}}, togglescratch, {.v = kittyscratchcmd } },

  // Lock screen
	{ 1, {{MODKEY, Key_l}}, spawn, SHCMD("/etc/scripts/system/sway-lock.sh") },

  // Open power menu
  { 1, {{MODKEY, Key_Escape}}, spawn, SHCMD("rofi-powermenu") },

  // Open app launcher
	{ 1, {{MODKEY, Key_space}}, spawn, {.v = menucmd} },

  // Take fullscreen screenshoot
  { 1, {{MODKEY, Key_Print}}, spawn, SHCMD("/etc/scripts/system/takeshot.sh --now") },

  // Open calc
  { 1, {{MODKEY, Key_c}}, spawn, SHCMD("rofi-calc") },

  // Show clipboard
  { 1, {{MODKEY, Key_v}}, spawn, SHCMD("/etc/scripts/system/clipboard-manager.sh --menu") },

  // Clear clipboard
  { 1, {{MODKEY|MOD_SHIFT, Key_v}}, spawn, SHCMD("/etc/scripts/system/clipboard-manager.sh --clear") },

  // Show emojis
  { 1, {{MODKEY, Key_e}}, spawn, SHCMD("rofi-emoji") },

  // Show last notification
  { 1, {{MODKEY|MOD_CONTROL, Key_n}}, spawn, SHCMD("dunstctl history-pop") },

  // Hide recent notification
  { 1, {{MODKEY|MOD_CONTROL|MOD_SHIFT, Key_n}}, spawn, SHCMD("dunstctl close") },

  // Hide all notifications
  { 1, {{MODKEY|MOD_CONTROL|MOD_SHIFT, Key_Escape}}, spawn, SHCMD("dunstctl close-all") },

  // Toggle bar
  { 1, {{MODKEY, Key_b}}, spawn, SHCMD("/etc/scripts/waybar/waybar-toggle.sh") },


  // ### WM KEYBINDINGS

  // Close focused view
  { 1, {{MODKEY|MOD_SHIFT, Key_w}}, killclient, {0} },

  // Toggle float
  { 1, {{MODKEY, Key_s}}, togglefloating, {0} },

  // Toggle fullscreen
  { 1, {{MODKEY, Key_f}}, togglefullscreen, {0} },

  // Toggle sticky
  { 1, {{MODKEY|MOD_CONTROL, Key_y}}, togglesticky, {0} },

  // Toggle visibility
  { 1, {{MODKEY, Key_h}}, toggle_visibility, {0} },

  // Focus direction
  { 1, {{MODKEY, Key_n}}, focusstack, {.i = +1} },
  { 1, {{MODKEY, Key_p}}, focusstack, {.i = -1} },

  // Swap direction
  { 1, {{MODKEY|MOD_SHIFT, Key_n}}, movestack, {.i = +1} },
  { 1, {{MODKEY|MOD_SHIFT, Key_p}}, movestack, {.i = -1} },

  // Focus next/previous monitor
  { 1, {{MODKEY, Key_comma}}, focusmon, {.i = WLR_DIRECTION_LEFT} },
  { 1, {{MODKEY, Key_period}}, focusmon, {.i = WLR_DIRECTION_RIGHT} },

  // Send focused view to the next/previous monitor
  { 1, {{MODKEY|MOD_SHIFT, Key_comma}}, tagmon, {.i = WLR_DIRECTION_LEFT} },
  { 1, {{MODKEY|MOD_SHIFT, Key_period}}, tagmon, {.i = WLR_DIRECTION_RIGHT} },

  // Bump focused view to the top of the layout stack
  { 1, {{MODKEY, Key_Return}}, zoom, {0} },

  // Toggle gaps
  { 2, {{MODKEY, Key_r}, {MOD_NONE, Key_grave}}, togglegaps, {0} },

  // To decrease/increase the main ratio
  { 2, {{MODKEY, Key_r}, {MOD_NONE, Key_Left}}, incnmaster, {.i = +1} },
  { 2, {{MODKEY, Key_r}, {MOD_NONE, Key_Right}}, incnmaster, {.i = -1} },

  // To increment/decrement the main count
  { 2, {{MODKEY, Key_r}, {MOD_SHIFT, Key_Left}}, setmfact, {.f = -0.05} },
  { 2, {{MODKEY, Key_r}, {MOD_SHIFT, Key_Right}}, setmfact, {.f = +0.05} },

  // Change layout
  { 2, {{MODKEY, Key_r}, {MOD_NONE, Key_comma}}, cyclelayout, {.i = -1 } },
  { 2, {{MODKEY, Key_r}, {MOD_NONE, Key_period}}, cyclelayout, {.i = +1 } },
  { 2, {{MODKEY, Key_r}, {MOD_NONE, Key_t}}, setlayout, {.v = &layouts[0]} },
  { 2, {{MODKEY, Key_r}, {MOD_NONE, Key_f}}, setlayout, {.v = &layouts[1]} },
  { 2, {{MODKEY, Key_r}, {MOD_NONE, Key_m}}, setlayout, {.v = &layouts[2]} },
  { 2, {{MODKEY, Key_r}, {MOD_NONE, Key_c}}, setlayout, {.v = &layouts[3]} },
  { 2, {{MODKEY, Key_r}, {MOD_NONE, Key_g}}, setlayout, {.v = &layouts[4]} },
  { 2, {{MODKEY, Key_r}, {MOD_NONE, Key_s}}, setlayout, {.v = &layouts[5]} },
  { 2, {{MODKEY, Key_r}, {MOD_NONE, Key_w}}, setlayout, {.v = &layouts[6]} },
  { 2, {{MODKEY, Key_r}, {MOD_NONE, Key_d}}, setlayout, {.v = &layouts[7]} },
  // { 1, {{MODKEY, Key_space}}, setlayout, {0} },


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

  // { 1, {{MODKEY|MOD_SHIFT, Key_0}}, tag, {.ui = ~0} },

  // Focus previous tags
  { 1, {{MODKEY, Key_grave}}, view, {0} },

  // Focus all tags
  { 1, {{MODKEY, Key_0}}, view, {.ui = ~0} },


  // ### APPLICATION KEYBINDINGS (Super + Alt + Key)

  // Open primary terminal
	{ 1, {{MODKEY|MOD_ALT, Key_t}}, spawn, {.v = termcmd} },

  // Open file manager
  { 1, {{MODKEY|MOD_ALT, Key_f}}, togglescratch, {.v = fmscratchcmd} },

  // Screencast/record region to mp4
  { 1, {{MODKEY|MOD_ALT, Key_r}}, spawn, SHCMD("/etc/scripts/system/recorder.sh --area") },

  // Open screenshoot utility
  { 1, {{MODKEY|MOD_ALT, Key_s}}, spawn, SHCMD("/etc/scripts/system/takeshot.sh --area") },

  // Open color picker
  { 1, {{MODKEY|MOD_ALT, Key_c}}, spawn, SHCMD("/etc/scripts/system/color-picker.sh") },

  // Open Browser
  { 2, {{MODKEY|MOD_ALT, Key_b}, {MOD_NONE, Key_f}}, spawn, RUN("firefox") },
  { 2, {{MODKEY|MOD_ALT, Key_b}, {MOD_NONE, Key_b}}, spawn, RUN("brave") },
  { 2, {{MODKEY|MOD_ALT, Key_b}, {MOD_NONE, Key_g}}, spawn, RUN("google-chrome-stable") },

  // Terminal TUI
  { 2, {{MODKEY|MOD_ALT, Key_u}, {MOD_NONE, Key_n}}, togglescratch, {.v = kittyneorgcmd} },
  { 2, {{MODKEY|MOD_ALT, Key_u}, {MOD_NONE, Key_m}}, togglescratch, {.v = kittytopcmd} },
  { 2, {{MODKEY|MOD_ALT, Key_u}, {MOD_NONE, Key_e}}, togglescratch, {.v = kittyneomuttcmd} },
  { 2, {{MODKEY|MOD_ALT, Key_u}, {MOD_NONE, Key_r}}, togglescratch, {.v = kittynewsboatcmd} },
  { 2, {{MODKEY|MOD_ALT, Key_u}, {MOD_NONE, Key_u}}, togglescratch, {.v = kittyncmpcppcmd} },


  // ### MEDIA KEYBINDINGS

  { 1, {{MOD_NONE, Key_XF86AudioRaiseVolume}}, spawn, SHCMD("wob-osd --volume +5%") },
  { 1, {{MOD_NONE, Key_XF86AudioLowerVolume}}, spawn, SHCMD("wob-osd --volume -5%") },
  { 1, {{MOD_NONE, Key_XF86AudioMute}}, spawn, SHCMD("wob-osd --volume-toggle") },

  { 1, {{MOD_NONE, Key_XF86AudioNext}}, spawn, SHCMD("playerctl next") },
  { 1, {{MOD_NONE, Key_XF86AudioPrev}}, spawn, SHCMD("playerctl previous") },
  { 1, {{MOD_NONE, Key_XF86AudioStop}}, spawn, SHCMD("playerctl pause") },
  { 1, {{MOD_NONE, Key_XF86AudioPlay}}, spawn, SHCMD("playerctl play-pause") },

  { 1, {{MOD_NONE, Key_XF86MonBrightnessUp}}, spawn, SHCMD("wob-osd --backlight 5%+") },
  { 1, {{MOD_NONE, Key_XF86MonBrightnessDown}}, spawn, SHCMD("wob-osd --backlight 5%-") },

  { 1, {{MOD_NONE, Key_XF86KbdBrightnessUp}}, spawn, SHCMD("wob-osd --kbd-backlight 5%+") },
  { 1, {{MOD_NONE, Key_XF86KbdBrightnessDown}}, spawn, SHCMD("wob-osd --kbd-backlight 5%-") },


  // ### OTHERS

  // { 1, {{MODKEY, Key_a}}, shiftview, { .i = -1 } },
  // { 1, {{MODKEY, Key_semicolon}}, shiftview, { .i = 1 } },

  { 1, {{MODKEY, Key_o}}, menu, {.v = &menus[0]} },
  { 1, {{MODKEY|MOD_SHIFT, Key_o}}, menu, {.v = &menus[1]} },

  { 1, {{MODKEY|MOD_CONTROL|MOD_SHIFT, Key_q}}, quit, {0} },

	/* Ctrl-Alt-Backspace and Ctrl-Alt-Fx used to be handled by X server */
	{ 1, {{MOD_CONTROL|MOD_ALT,Key_BackSpace}}, quit, {0} },
#define CHVT(KEY,n) { 1, {{MOD_CONTROL|MOD_ALT,KEY}}, chvt, {.ui = (n)} }
	CHVT(Key_F1, 1), CHVT(Key_F2,  2),  CHVT(Key_F3,  3),  CHVT(Key_F4,  4),
	CHVT(Key_F5, 5), CHVT(Key_F6,  6),  CHVT(Key_F7,  7),  CHVT(Key_F8,  8),
	CHVT(Key_F9, 9), CHVT(Key_F10, 10), CHVT(Key_F11, 11), CHVT(Key_F12, 12),
};

static const Button buttons[] = {
	{ MODKEY, BTN_LEFT,   moveresize,     {.ui = CurMove} },
	{ MODKEY, BTN_MIDDLE, togglefloating, {0} },
	{ MODKEY, BTN_RIGHT,  moveresize,     {.ui = CurResize} },
};
