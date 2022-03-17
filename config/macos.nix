{ config, lib, pkgs, inputs, ... }:

let localPkgs = import ./packages { inherit pkgs lib; };
in {
  imports = [
    ./mixins/darwin.nix
    ./mixins/lorri
    ./mixins/nix-common.nix
    ./mixins/overlays.nix
    ./users/user-macos.nix
    ./mixins/pkgs-node.nix
  ];

  config = {
    _displayServer = "darwin";

    nixpkgs.overlays = with inputs; [
      nur.overlay
      spacebar.overlay
      (final: prev: {
        sf-mono-liga-bin = localPkgs.sf-mono-liga-bin;
        # yabai is broken on macOS 12, so lets make a smol overlay to use the master version
        yabai = let
          version = "4.0.0-dev";
          buildSymlinks = prev.runCommand "build-symlinks" { } ''
            mkdir -p $out/bin
            ln -s /usr/bin/xcrun /usr/bin/xcodebuild /usr/bin/tiffutil /usr/bin/qlmanage $out/bin
          '';
        in prev.yabai.overrideAttrs (old: {
          inherit version;
          src = inputs.yabai-src;

          buildInputs = with prev.darwin.apple_sdk.frameworks; [
            Carbon
            Cocoa
            ScriptingBridge
            prev.xxd
            SkyLight
          ];

          nativeBuildInputs = [ buildSymlinks ];
        });
      })
    ];

    environment = {
      etc = {
        # TODO: chmod 440
        "sudoers.d/10-nix-commands".source = ./dotfiles-darwin/10-nix-commands;
      };
    };

    services.yabai = {
      enable = true;
      enableScriptingAddition = true;
      package = pkgs.yabai;
      enableScriptingAddition = false;
      config = {
        # layout
        layout = "bsp";
        auto_balance = "on";
        split_ratio = "0.50";
        window_placement = "second_child";
        # Gaps
        window_gap = 18;
        top_padding = 18;
        bottom_padding = 46;
        left_padding = 18;
        right_padding = 18;
        # shadows and borders
        window_shadow = "on";
        window_border = "off";
        window_border_width = 3;
        window_opacity = "on";
        window_opacity_duration = "0.1";
        active_window_opacity = "1.0";
        normal_window_opacity = "1.0";
        # mouse
        mouse_modifier = "cmd";
        mouse_action1 = "move";
        mouse_action2 = "resize";
        mouse_drop_action = "swap";
      };
      extraConfig = ''
        # rules
        yabai -m rule --add app='Firefox' manage=on
        yabai -m rule --add app='System Preferences' manage=off
        yabai -m rule --add app='Activity Monitor' manage=off
      '';
    };

    services.spacebar = {
      enable = true;
      package = pkgs.spacebar;
      config = {
        position = "bottom";
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
  };

  # homebrew = {
  #   brewPrefix = "/opt/homebrew/bin";
  #   enable = true;
  #   autoUpdate = true;
  #   cleanup = "zap"; # keep it clean
  #   global = {
  #     brewfile = true;
  #     noLock = true;
  #   };
  #
  #   taps = [
  #     "homebrew/core" # core
  #     "homebrew/cask" # we're using this for casks, after all
  #     "homebrew/cask-versions" # needed for firefox-nightly and discord-canary
  #   ];
  #
  #   casks = [
  #     "raycast" # Launcher
  #     "prusaslicer" # 3d printing
  #     "discord-canary" # discord for macOS
  #     "firefox-nightly" # my browser of choice
  #     "nvidia-geforce-now" # game streaming
  #   ];
  # };

}
