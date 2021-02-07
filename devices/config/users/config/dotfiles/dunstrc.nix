{
  global = {
    title = "Dunst";
    class = "Dunst";
    monitor = 0;
    follow = "mouse";

    # The geometry of the window. Format: [{width}]x{height}[+/-{x}+/-{y}]
    # The height = number of notifications, all other variables are px
    # Omit width, provide height for full-screen width notifications
    # If width is 0, window will fit to longest message
    # Positive x value is measured from the left of the screen, negative x is measured from the right
    # Positive y value is measured from the top of the screen
    geometry = "350x6-16+84";

    indicate_hidden = "yes";
    shrink = "yes";

    transparency = 0;
    separator_height = 2;
    padding = 8;
    horizontal_padding = 13;
    frame_width = 8;
    frame_color = "#1C1E27";
    separator_color = "#404859";

    font = "Inconsolata Bold 11";

    line_height = 0;
    markup = "full";
    format = "<span size='x-large' font_desc='Inconsolata 11' weight='bold' foreground='#B367CF'>%s</span>\n\n%b";
    alignment = "center";

    idle_threshold = 120;
    show_age_threshold = 60;
    sort = "no";
    word_wrap = "yes";
    ignore_newline = "no";
    stack_duplicates = false;
    hide_duplicate_count = "yes";
    show_indicators = "no";
    sticky_history = "no";
    history_length = 20;
    always_run_script = true;
    corner_radius = 0;
    icon_position = "left";
    max_icon_size = 96;

    # icon_path = /usr/share/icons/Papirus-Dark-Custom/48x48/actions/:/usr/share/icons/Papirus-Dark-Custom/48x48/apps/:/usr/share/icons/Papirus-Dark-Custom/48x48/devices/:/usr/share/icons/Papirus-Dark-Custom/48x48/emblems/:/usr/share/icons/Papirus-Dark-Custom/48x48/emotes/:/usr/share/icons/Papirus-Dark-Custom/48x48/mimetypes/:/usr/share/icons/Papirus-Dark-Custom/48x48/places/:/usr/share/icons/Papirus-Dark-Custom/48x48/status/;
    # icon_path = "${pkgs.papirus-icon-theme}/share/icons/Papirus-Dark-Custom/48x48/actions/";

    browser = "firefox";

    mouse_left_click = "close_current";
    mouse_middle_click = "do_action";
    mouse_right_click = "close_all";
  };
  shortcuts = {
    close = "ctrl+space";
    close_all = "ctrl+shift+space";
    history = "ctrl+Escape";
    context = "ctrl+shift+period";
  };
  urgency_low = {
    # IMPORTANT: colors have to be defined in quotation marks.
    # Otherwise the "#" and following would be interpreted as a comment.
    background = "#1C1E27";
    foreground = "#cacacc";
    timeout = 5 ;
    # Icon for notifications with low urgency, uncomment to enable
    #icon = /path/to/icon;
  };
  urgency_normal = {
    background = "#1C1E27";
    foreground = "#cacacc";
    timeout = 5;
    # Icon for notifications with normal urgency, uncomment to enable
    #icon = /path/to/icon;
  };
  urgency_critical = {
    background = "#1C1E27";
    foreground = "#cacacc";
    timeout = 120;
  };
}
