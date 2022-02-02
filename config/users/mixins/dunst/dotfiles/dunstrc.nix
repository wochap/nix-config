{ config, pkgs, lib, ... }:

let
  localPkgs = import ../../../../packages { pkgs = pkgs; lib = lib; };
  border = "#44475a";
  borderWidth = 3;
  timeout = 60000;
  fontSize = if (config.services.xserver.dpi == 192) then 7.5 else 10;
in
{
  global = {
    origin = "top-right";
    # offset top === 25 + 25 + 54
    offset = "25x104";
    browser = "xdg-open";
    notification_limit = "4";
    always_run_script = true;
    class = "Dunst";
    follow = "mouse";
    hide_duplicate_count = true;
    history_length = 20;
    idle_threshold = timeout;
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

    # Theme settings
    width = "500";
    height = "130";
    word_wrap = true;
    ellipsize = "end";
    scale = 1;
    alignment = "left";
    vertical_alignment = "center";
    corner_radius = 10;
    font = "FiraCode Nerd Font Mono ${toString fontSize}";
    format = ''<b>%s</b> <span color='#8be9fd'>(%a)</span>\n%b'';
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
    script = "/etc/scripts/play_notification.sh";
    summary = "*";
  };

  urgency_low = {
    background = "#282a36";
    foreground = "#6272a4";
    timeout = timeout;
    icon = "${localPkgs.whitesur-dark-icons}/share/icons/WhiteSur-dark/256x256/apps/userinfo.png";
  };
  urgency_normal = {
    background = "#282a36";
    foreground = "#f8f8f2";
    timeout = timeout;
    icon = "${localPkgs.whitesur-dark-icons}/share/icons/WhiteSur-dark/256x256/apps/userinfo.png";
  };
  urgency_critical = {
    background = "#282a36";
    foreground = "#bd93f9";
    timeout = timeout;
    icon = "${localPkgs.whitesur-dark-icons}/share/icons/WhiteSur-dark/256x256/apps/userinfo.png";
  };

  slack = {
    appname = "Slack";
    new_icon = "${localPkgs.whitesur-dark-icons}/share/icons/WhiteSur-dark/256x256/apps/slack.png";
  };
  evolution = {
    appname = "Evolution";
    new_icon = "${localPkgs.whitesur-dark-icons}/share/icons/WhiteSur-dark/256x256/apps/slack.png";
    timeout = timeout;
    set_transient = false;
  };
}
