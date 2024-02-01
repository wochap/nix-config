{ config, lib, ... }:

let
  inherit (config._custom.globals) userName;
  cfg = config._custom.de.gdm;
in {
  options._custom.de.gdm = {
    enable = lib.mkEnableOption { };
    enableAutoLogin = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      services.xserver.displayManager.gdm.enable = true;
      services.xserver.displayManager.gdm.wayland = true;

    }
    (lib.mkIf cfg.enableAutoLogin {

      # Enable automatic login for the user.
      services.xserver.displayManager.autoLogin.enable = true;
      services.xserver.displayManager.autoLogin.user = userName;

      # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
      systemd.services."getty@tty1".enable = false;
      systemd.services."autovt@tty1".enable = false;
    })
  ]);
}

