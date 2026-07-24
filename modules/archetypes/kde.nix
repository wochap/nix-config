{
  config,
  lib,
  pkgs,
  ...
}:

{
  options._custom.archetypes.kde.enable = lib.mkEnableOption { };

  config = lib.mkIf config._custom.archetypes.kde.enable {
    _custom.home-manager.enable = true;
    _custom.nix.enable = true;
    _custom.globals.enable = true;

    _custom.archetypes.de-wayland-desktop.enable = true;

    _custom.desktop.audio.enable = true;
    _custom.desktop.audio.enableEasyeffects = lib.mkDefault true;
    _custom.desktop.audio.enableNoisetorch = lib.mkDefault true;
    _custom.desktop.bluetooth.enable = true;

    _custom.desktop.kde.enable = lib.mkForce true;

    _custom.system.internationalization.enable = true;
    _custom.system.user.enable = true;
  };
}
