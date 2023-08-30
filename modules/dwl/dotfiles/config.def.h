/* appearance */
static const int sloppyfocus               = 1;  /* focus follows mouse */
static const int bypass_surface_visibility = 0;  /* 1 means idle inhibitors will disable idle tracking even if it's surface isn't visible  */
static const int smartgaps                 = 0;  /* 1 means no outer gap when there is only one window */
static const unsigned int borderpx         = 2;  /* border pixel of windows */
static const unsigned int gappx            = 7; /* horiz inner gap between windows */
static const float bordercolor[]           = {0.5, 0.5, 0.5, 1.0};
static const float focuscolor[]            = {1.0, 0.0, 0.0, 1.0};
static const char cursortheme[]            = "capitaine-cursors"; /* theme from /usr/share/cursors/xorg-x11 */
static const unsigned int cursorsize       = 24;
/* To conform the xdg-protocol, set the alpha to zero to restore the old behavior */
static const float fullscreen_bg[]         = {0.1, 0.1, 0.1, 1.0};

/* Autostart */
static const char *const autostart[] = {
  "restart-pipewire-and-portal-services", NULL,
  "configure-gtk", NULL,

  // start systemd services related to graphical-session.target
  // https://github.com/emersion/xdg-desktop-portal-wlr/wiki/systemd-user-services,-pam,-and-environment-variables
  "systemctl --user start graphical-session.target", NULL,

  // "bash", "/etc/scripts/dwl-autostart.sh", NULL,
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
	{ "xdg-desktop-portal-gtk",  NULL,       0,         1,          1,          0,        -1,      0,   0,   0,    0,      0,          0,      0 },

	{ "firefox",                 NULL,       1 << 4,    0,          0,          0,        -1,      0,   0,   0,    0,      0,          0,      0 },
	{ "google-chrome",           NULL,       1 << 0,    0,          0,          0,        -1,      0,   0,   0,    0,      0,          0,      0 },
	{ "brave-browser",           NULL,       1 << 7,    0,          0,          0,        -1,      0,   0,   0,    0,      0,          0,      0 },
	{ "Slack",                   NULL,       1 << 3,    0,          0,          0,        -1,      0,   0,   0,    0,      0,          0,      0 },

	{ "kitty-top",               NULL,       0,         1,          1,          1,        -1,      0,   0,   0,    0,      0,          0,      0 },
	{ "kitty-scratch",           NULL,       0,         1,          1,          1,        -1,      0,   0,   0,    0,      0,          0,      0 },
	{ "kitty-neorg",             NULL,       0,         1,          1,          1,        -1,      0,   0,   0,    0,      0,          0,      0 },
	{ "kitty-nmtui",             NULL,       0,         1,          1,          1,        -1,      0,   0,   0,    0,      0,          0,      0 },
	{ "kitty-neomutt",           NULL,       0,         1,          1,          1,        -1,      0,   0,   0,    0,      0,          0,      0 },
	{ "kitty-newsboat",          NULL,       0,         1,          1,          1,        -1,      0,   0,   0,    0,      0,          0,      0 },
	{ "kitty-ncmpcpp",           NULL,       0,         1,          1,          1,        -1,      0,   0,   0,    0,      0,          0,      0 },

	{ NULL,                    "scratchpad", 0,         1,          1,          0,        -1,      0,   0,   0,    0,      's',        0,      0 },
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
	/* defaults */
	{ NULL,       0.64, 1,      2,    &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL,   -1,  -1 },
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
#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

/* commands */
static const char *termcmd[] = { "kitty", NULL };
static const char *menucmd[] = { "rofi-launcher", NULL };

#include "shiftview.c"

/* named scratchpads - First arg only serves to match against key in rules*/
static const char *scratchpadcmd[] = { "s", "alacritty", "-t", "scratchpad", NULL };

#include "keys.h"
static const Keychord keychords[] = {
	/* Note that Shift changes certain key codes: c -> C, 2 -> at, etc. */
	/* count key_sequences                                    function          argument */
	{ 1, {{MODKEY, Key_p}},                               spawn,            {.v = menucmd} },
	{ 1, {{MODKEY|WLR_MODIFIER_SHIFT, Key_Return}},       spawn,            {.v = termcmd} },
	{ 1, {{MODKEY, Key_b}},                               toggle_visibility,{0} },
	{ 1, {{MODKEY, Key_grave}},                           togglescratch,    {.v = scratchpadcmd } },
	{ 1, {{MODKEY, Key_j}},                               focusstack,       {.i = +1} },
	{ 1, {{MODKEY, Key_k}},                               focusstack,       {.i = -1} },
	{ 1, {{MODKEY|WLR_MODIFIER_SHIFT, Key_j}},            movestack,        {.i = +1} },
	{ 1, {{MODKEY|WLR_MODIFIER_SHIFT, Key_k}},            movestack,        {.i = -1} },
	{ 1, {{MODKEY, Key_i}},                               incnmaster,       {.i = +1} },
	{ 1, {{MODKEY, Key_d}},                               incnmaster,       {.i = -1} },
	{ 1, {{MODKEY, Key_h}},                               setmfact,         {.f = -0.05} },
	{ 1, {{MODKEY, Key_l}},                               setmfact,         {.f = +0.05} },
	{ 1, {{MODKEY, Key_Return}},                          zoom,             {0} },
	{ 1, {{MODKEY, Key_Tab}},                             view,             {0} },
	{ 1, {{MODKEY, Key_g}},                               togglegaps,       {0} },
	{ 1, {{MODKEY, Key_a}},                               shiftview,        { .i = -1 } },
	{ 1, {{MODKEY, Key_semicolon}},                       shiftview,        { .i = 1 } },
	{ 1, {{MODKEY|WLR_MODIFIER_SHIFT, Key_c}},            killclient,       {0} },
	{ 1, {{MODKEY, Key_t}},                               setlayout,        {.v = &layouts[0]} },
	{ 1, {{MODKEY, Key_f}},                               setlayout,        {.v = &layouts[1]} },
	{ 1, {{MODKEY, Key_m}},                               setlayout,        {.v = &layouts[2]} },
	{ 1, {{MODKEY, Key_c}},                               setlayout,        {.v = &layouts[3]} },
	{ 1, {{MODKEY, Key_g}},                               setlayout,        {.v = &layouts[4]} },
	{ 1, {{MODKEY, Key_s}},                               setlayout,        {.v = &layouts[6]} },
	{ 1, {{MODKEY|WLR_MODIFIER_CTRL, Key_comma}},         cyclelayout,      {.i = -1 } },
	{ 1, {{MODKEY|WLR_MODIFIER_CTRL, Key_period}},        cyclelayout,      {.i = +1 } },
	{ 1, {{MODKEY, Key_space}},                           setlayout,        {0} },
	{ 1, {{MODKEY, Key_o}},                               menu,             {.v = &menus[0]} },
	{ 1, {{MODKEY|WLR_MODIFIER_SHIFT, Key_o}},            menu,             {.v = &menus[1]} },
	{ 1, {{MODKEY|WLR_MODIFIER_SHIFT, Key_space}},        togglefloating,   {0} },
	{ 1, {{MODKEY, Key_s}},                               togglesticky,     {0} },
	{ 1, {{MODKEY, Key_e}},                               togglefullscreen, {0} },
	{ 1, {{MODKEY, Key_0}},                               view,             {.ui = ~0} },
	{ 1, {{MODKEY|WLR_MODIFIER_SHIFT, Key_0}},            tag,              {.ui = ~0} },
	{ 1, {{MODKEY, Key_comma}},                           focusmon,         {.i = WLR_DIRECTION_LEFT} },
	{ 1, {{MODKEY, Key_period}},                          focusmon,         {.i = WLR_DIRECTION_RIGHT} },
	{ 1, {{MODKEY|WLR_MODIFIER_SHIFT, Key_comma}},        tagmon,           {.i = WLR_DIRECTION_LEFT} },
	{ 1, {{MODKEY|WLR_MODIFIER_SHIFT, Key_period}},       tagmon,           {.i = WLR_DIRECTION_RIGHT} },
	TAGKEYS(                     Key_1,                   0),
	TAGKEYS(                     Key_2,                   1),
	TAGKEYS(                     Key_3,                   2),
	TAGKEYS(                     Key_4,                   3),
	TAGKEYS(                     Key_5,                   4),
	TAGKEYS(                     Key_6,                   5),
	TAGKEYS(                     Key_7,                   6),
	TAGKEYS(                     Key_8,                   7),
	TAGKEYS(                     Key_9,                   8),
	{ 1, {{MODKEY|MOD_SHIFT, Key_q}},                     quit,             {0} },

	/* Ctrl-Alt-Backspace and Ctrl-Alt-Fx used to be handled by X server */
	{ 1, {{WLR_MODIFIER_CTRL|WLR_MODIFIER_ALT,Key_BackSpace}}, quit, {0} },
#define CHVT(KEY,n) { 1, {{WLR_MODIFIER_CTRL|WLR_MODIFIER_ALT,KEY}}, chvt, {.ui = (n)} }
	CHVT(Key_F1, 1), CHVT(Key_F2,  2),  CHVT(Key_F3,  3),  CHVT(Key_F4,  4),
	CHVT(Key_F5, 5), CHVT(Key_F6,  6),  CHVT(Key_F7,  7),  CHVT(Key_F8,  8),
	CHVT(Key_F9, 9), CHVT(Key_F10, 10), CHVT(Key_F11, 11), CHVT(Key_F12, 12),
};

static const Button buttons[] = {
	{ MODKEY, BTN_LEFT,   moveresize,     {.ui = CurMove} },
	{ MODKEY, BTN_MIDDLE, togglefloating, {0} },
	{ MODKEY, BTN_RIGHT,  moveresize,     {.ui = CurResize} },
};
