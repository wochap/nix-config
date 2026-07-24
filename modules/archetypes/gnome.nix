{
  config,
  lib,
  pkgs,
  ...
}:

{
  options._custom.archetypes.gnome.enable = lib.mkEnableOption { };

  config = lib.mkIf config._custom.archetypes.gnome.enable {
    _custom.home-manager.enable = true;
    _custom.nix.enable = true;
    _custom.globals.enable = true;

    _custom.archetypes.de-wayland-desktop.enable = true;

    _custom.security.gnome-keyring.enable = lib.mkDefault true;

    _custom.desktop.gnome.enable = lib.mkForce true;
  };
}
