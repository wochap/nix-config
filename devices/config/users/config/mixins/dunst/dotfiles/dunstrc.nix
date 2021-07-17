{ pkgs, ... }:

let
  localPkgs = import ../../../../../packages { pkgs = pkgs; };
  background = "#FF5C57"; #RRGGBBAA
  border = "#cb1401";
  borderWidth = 3;
  foreground = "#2e0301";
in
{
  global = {
    # The geometry of the window. Format: [{width}]x{height}[+/-{x}+/-{y}]
    # The height = number of notifications, all other variables are px
    # Omit width, provide height for full-screen width notifications
    # If width is 0, window will fit to longest message
    # Positive x value is measured from the left of the screen, negative x is measured from the right
    # Positive y value is measured from the top of the screen
    geometry = "500x6-25-25";
    # browser = "/etc/open_url.sh";
    always_run_script = true;
    class = "Dunst";
    follow = "mouse";
    hide_duplicate_count = true;
    history_length = 20;
    idle_threshold = 60000;
    ignore_newline = false;
    indicate_hidden = true;
    markup = "full";
    monitor = 0;
    mouse_left_click = "close_current";
    mouse_middle_click = "do_action";
    mouse_right_click = "close_all";
    show_age_threshold = -1;
    show_indicators = false;
    shrink = false;
    sort = false;
    stack_duplicates = false;
    sticky_history = false;
    title = "Dunst";
    word_wrap = true;

    # Theme settings
    alignment = "left";
    background = background;
    corner_radius = 20;
    font = "Inter 11";
    format = "<span weight='600'>%s</span>\\n<span>%b</span>";
    frame_color = border;
    frame_width = borderWidth;
    horizontal_padding = 16;
    icon_position = "left";
    line_height = "1.5";
    max_icon_size = 80;
    min_icon_size = 80;
    padding = 16;
    separator_color = border;
    separator_height = borderWidth;
    transparency = 0;
  };
  play_sound = {
    script = "/etc/play_notification.sh";
    summary = "*";
  };
  shortcuts = {
    # close_all = "ctrl+shift+space";
    # context = "ctrl+shift+period";
    close = "ctrl+space";
    history = "ctrl+Escape";
  };
  urgency_low = {
    background = background;
    foreground = foreground;
    timeout = 60000;
  };
  urgency_normal = {
    background = background;
    foreground = foreground;
    timeout = 60000;
    icon = "${localPkgs.whitesur-dark-icons}/share/icons/WhiteSur-dark/256x256/apps/userinfo.png";
  };
  urgency_critical = {
    background = background;
    foreground = foreground;
    timeout = 60000;
  };
  slack = {
    appname = "Slack";
    new_icon = "${localPkgs.whitesur-dark-icons}/share/icons/WhiteSur-dark/256x256/apps/slack.png";
  };
  # evolution = {
  #   appname = "Evolution";
  #   new_icon = "${localPkgs.whitesur-dark-icons}/share/icons/WhiteSur-dark/256x256/apps/slack.png";
  # };
}
