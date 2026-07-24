{
  config,
  lib,
  pkgs,
  ...
}:

{
  options._custom.archetypes.de-wayland-desktop.enable = lib.mkEnableOption { };

  config = lib.mkIf config._custom.archetypes.de-wayland-desktop.enable {
    _custom.home-manager.enable = true;
    _custom.nix.enable = true;
    _custom.globals.enable = true;

    _custom.security.doas.enable = true;
    _custom.security.gpg.enable = true;
    _custom.security.ssh.enable = true;

    _custom.system.apple.enable = lib.mkDefault false;
    _custom.system.console.enable = true;
    _custom.system.fhs-compat.enable = true;
    _custom.system.others.enable = true;
    _custom.system.windows.enable = lib.mkDefault true;
    _custom.system.windows.enableSamba = lib.mkDefault true;
    _custom.system.internationalization.enable = true;
    _custom.system.user.enable = true;

    _custom.desktop.fastfetch.enable = true;
    _custom.desktop.fonts.enable = true;
    _custom.desktop.gtk.enable = true;
    _custom.desktop.gtk.enableCsd = true;
    _custom.desktop.gtk.enableTheme = false;
    _custom.desktop.networking.enable = true;
    _custom.desktop.networking.enableWifi = true;
    _custom.desktop.plymouth.enable = true;
    _custom.desktop.power-management.enable = true;
    _custom.desktop.qt.enable = true;
    _custom.desktop.qt.enableTheme = false;

    _custom.desktop.electron-support.enable = true;
    _custom.desktop.wayland-utils.enable = true;
  };
}
