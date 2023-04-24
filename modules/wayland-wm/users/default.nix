{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.waylandWm;
  userName = config._userName;
in {
  imports = [
    ./mixins/kanshi.nix
    ./mixins/mako
    ./mixins/rofi
    ./mixins/swww
    ./mixins/system
    ./mixins/way-displays
    ./mixins/waybar
    ./mixins/wofi
  ];
}
