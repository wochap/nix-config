{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.waylandWm;
  userName = config._userName;
in {
  imports = [
    ./mixins/dunst
    ./mixins/kanshi.nix
    ./mixins/rofi
    ./mixins/swww
    ./mixins/system
    ./mixins/way-displays
    ./mixins/waybar
    ./mixins/wob
    ./mixins/wofi
  ];
}
