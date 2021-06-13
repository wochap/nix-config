{
  global = {
    # The geometry of the window. Format: [{width}]x{height}[+/-{x}+/-{y}]
    # The height = number of notifications, all other variables are px
    # Omit width, provide height for full-screen width notifications
    # If width is 0, window will fit to longest message
    # Positive x value is measured from the left of the screen, negative x is measured from the right
    # Positive y value is measured from the top of the screen
    geometry = "500x6-16-16";
    background = "#202020FF"; #RRGGBBAA
    alignment = "left";
    always_run_script = true;
    # browser = "/etc/open_url.sh";
    class = "Dunst";
    corner_radius = 0;
    follow = "mouse";
    font = "Iosevka 11";
    format = "<span weight='600'>%s</span>\\n<span>%b</span>";
    frame_color = "#282e3a";
    frame_width = 2;
    hide_duplicate_count = true;
    history_length = 20;
    horizontal_padding = 16;
    icon_position = "left";
    idle_threshold = 120;
    ignore_newline = false;
    indicate_hidden = true;
    line_height = 0;
    markup = "full";
    max_icon_size = 96;
    min_icon_size = 64;
    monitor = 0;
    mouse_left_click = "close_current";
    mouse_middle_click = "do_action";
    mouse_right_click = "close_all";
    padding = 16;
    separator_color = "#282e3a";
    separator_height = 2;
    show_age_threshold = 60;
    show_indicators = false;
    shrink = false;
    sort = false;
    stack_duplicates = false;
    sticky_history = false;
    title = "Dunst";
    transparency = 0;
    word_wrap = true;
  };
  play_sound = {
    script = "/etc/play_notification.sh";
    summary = "*";
  };
  shortcuts = {
    close = "ctrl+space";
    # close_all = "ctrl+shift+space";
    # context = "ctrl+shift+period";
    history = "ctrl+Escape";
  };
  urgency_low = {
    background = "#202020FF";
    foreground = "#e9e8e9";
    timeout = 5;
  };
  urgency_normal = {
    background = "#202020FF";
    foreground = "#e9e8e9";
    timeout = 5;
  };
  urgency_critical = {
    background = "#202020FF";
    foreground = "#e9e8e9";
    timeout = 120;
  };
}
