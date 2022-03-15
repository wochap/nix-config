{ config, lib, pkgs, ... }:

{
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

    environment = {
      etc = {
        # TODO: chmod 440
        "sudoers.d/10-nix-commands".source = ./dotfiles-darwin/10-nix-commands;
      };
    };

    services.yabai = {
      enable = false;
      package = pkgs.yabai;
      enableScriptingAddition = false;
      config = {

      };
      extraConfig = ''
        yabai -m config focus_follows_mouse autofocus
        yabai -m config window_topmost on
        yabai -m config window_shadow float
        yabai -m config window_border on
        yabai -m config window_border_width 2
        yabai -m config active_window_border_color 0xFFADBF8A
        yabai -m config normal_window_border_color 0xFF555555
        yabai -m config split_ratio 0.50
        yabai -m config mouse_modifier cmd
        yabai -m config mouse_action1 move
        yabai -m config mouse_action2 resize
        yabai -m config mouse_drop_action swap
      '';
    };

    services.skhd = {
      enable = false;
      skhdConfig = ''
        # Focus desktop
        cmd + 1  : yabai -m display --focus 1
        cmd + 2  : yabai -m display --focus 2
        cmd + 3  : yabai -m display --focus 3
        cmd + 4  : yabai -m display --focus 4

        # Send window to desktop
        cmd + shift - 1  : yabai -m window --space 1
        cmd + shift - 2  : yabai -m window --space 2
        cmd + shift - 3  : yabai -m window --space 3
        cmd + shift - 4  : yabai -m window --space 4

        fn + cmd - f : yabai -m window --toggle zoom-fullscreen
      '';
    };
  };
}
