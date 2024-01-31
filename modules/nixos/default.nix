{ config, ... }:

let userName = config._userName;
in {
  imports = [
    ./cli
    ./dwl
    ./globals.nix
    ./gnome
    ./gui
    ./hyprland
    ./llm
    ./river
    ./services
    ./sway
    ./tui
    ./wayland-wm
    ./wm
  ];

  config.home-manager.users.${userName}.imports = [ ./symlinks ];
}
