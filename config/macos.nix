{ config, lib, pkgs, inputs, ... }:

let localPkgs = import ./packages { inherit pkgs lib; };
in {
  imports = [
    ./mixins/darwin.nix
    ./mixins/lorri
    ./mixins/nix-common.nix
    ./mixins/overlays.nix
    ./mixins/pkgs-node.nix
    ./mixins/pkgs-python.nix
    ./mixins/pkgs.nix
    ./users/user-macos.nix
  ];

  config = {
    _displayServer = "darwin";

    services.nix-daemon.enable = true;

    # sudo yabai --uninstall-sa
    # sudo yabai --install-sa
    # sudo yabai --load-sa
    services.yabai = {
      enable = true;
      # enableScriptingAddition = true;
      package = pkgs.yabai;
      config = {
        # layout
        layout = "bsp";
        auto_balance = "on";
        split_ratio = "0.50";
        window_placement = "second_child";
        window_topmost = "on";
        # Gaps
        window_gap = 0;
        top_padding = 0;
        bottom_padding = 0;
        left_padding = 0;
        right_padding = 0;
        # shadows and borders
        window_shadow = "on";
        window_border = "off";
        window_border_width = 3;
        window_opacity = "on";
        window_opacity_duration = "0.1";
        active_window_opacity = "1.0";
        normal_window_opacity = "1.0";
        # mouse
        focus_follows_mouse = "autofocus";
        # mouse_modifier = "alt";
        mouse_action1 = "move";
        mouse_action2 = "resize";
        mouse_drop_action = "swap";
      };
      extraConfig = ''
        # necessary to load scripting-addition during startup on macOS Big Sur
        # *yabai --load-sa* is configured to run through sudo without a password
        sudo yabai --load-sa
        yabai -m signal --add event=dock_did_restart action="sudo yabai --load-sa"

        # rules
        yabai -m rule --add app='System Preferences' manage=off
        yabai -m rule --add app='choose' manage=off
        yabai -m rule --add app='Activity Monitor' manage=off
        yabai -m rule --add app='Notes' manage=off
        yabai -m rule --add app='App Store' manage=off
        yabai -m rule --add app='Simulator' manage=off
      '';
    };

    services.spacebar = {
      enable = false;
      package = pkgs.spacebar;
      config = {
        position = "top";
        height = 28;
        title = "on";
        spaces = "on";
        power = "on";
        clock = "off";
        right_shell = "off";
        padding_left = 20;
        padding_right = 20;
        spacing_left = 25;
        spacing_right = 25;
        text_font = ''"Menlo:16.0"'';
        icon_font = ''"Menlo:16.0"'';
        background_color = "0xff161616";
        foreground_color = "0xffFFFFFF";
        space_icon_color = "0xff3ddbd9";
        power_icon_strip = " ";
        space_icon_strip = "一 二 三 四 五 六 七 八 九 十";
        spaces_for_all_displays = "on";
        display_separator = "on";
        display_separator_icon = "|";
        clock_format = ''"%d/%m/%y %R"'';
        right_shell_icon = " ";
        right_shell_command = "whoami";
      };
    };

    services.skhd = {
      enable = true;
      skhdConfig = builtins.readFile ./users/dotfiles-darwin/.skhdrc;
    };

    homebrew = {
      enable = true;
      autoUpdate = true;
      cleanup = "zap"; # uninstall
      global = {
        brewfile = true;
        noLock = true;
      };

      taps = [
        "homebrew/bundle"
        "homebrew/cask"
        "homebrew/cask-fonts"
        "homebrew/cask-versions"
        "homebrew/core"
        "homebrew/services"
        "mongodb/brew"
      ];

      casks = [
        "alt-tab"
        "bitwarden"
        "figma"
        "finicky"
        # "firefox"
        "google-chrome"
        "insomnia"
        "iterm2"
        "keka"
        "postman"
        "robo-3t"
        "smcfancontrol"
        # "visual-studio-code"
        "vlc"
        "zoom"
        # "obs"
        # "streamlabs-obs" # OBS with audio?
      ];

      brews = [
        "choose-gui"
        "jq"
        "lua-language-server"
        "mas"
        "mongodb-community@5.0"
        "mongodb-database-tools"
      ];

      masApps = {
        "CopyClip - Clipboard History" = 595191960;
        "Slack" = 803453959 ;
      };

      extraConfig = ''
        cask_args appdir: "/Applications"
      '';
    };
  };


}
