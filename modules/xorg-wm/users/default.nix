{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.xorgWm;
  userName = config._userName;
in {
  imports = [
    ./mixins/autorandr
    ./mixins/clipmenu.nix
    ./mixins/dunst
    ./mixins/picom
    ./mixins/polybar
    ./mixins/rofi
    ./mixins/xsettingsd
  ];

  config = lib.mkIf cfg.enable {
    home-manager.users.${userName} = {
      config = {
        xresources.extraConfig = ''
          ${builtins.readFile "${inputs.dracula-xresources}/Xresources"}
        '';
      };
    };
  };
}
