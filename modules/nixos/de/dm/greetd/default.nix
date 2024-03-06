{ config, pkgs, lib, ... }:

let
  cfg = config._custom.de.greetd;
  inherit (config._custom.globals) userName;
in {
  options._custom.de.greetd = {
    enable = lib.mkEnableOption { };
    enableAutoLogin = lib.mkEnableOption { };
    cmd = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.etc."greetd/environments".text = ''
      Hyprland
      dwl
      bash
      zsh
    '';

    services.xserver.displayManager.lightdm.enable = false;

    services.greetd = {
      enable = true;
      settings = {
        # TODO: autologin doesn't unlock gnome keyring
        initial_session = lib.mkIf cfg.enableAutoLogin {
          command = cfg.cmd;
          user = userName;
        };
        default_session = {
          command = ''
            ${pkgs.greetd.tuigreet}/bin/tuigreet --user-menu --window-padding 2 --time --remember --cmd "${cfg.cmd}"'';
          user = userName;
        };
      };
    };

    # HACK: stop printing status messages in tuigreet
    # https://github.com/apognu/tuigreet/issues/68#issuecomment-1192683029
    # https://www.reddit.com/r/NixOS/comments/u0cdpi/tuigreet_with_xmonad_how/
    systemd.services.greetd.serviceConfig = {
      Type = "idle";

      StandardInput = "tty";
      StandardOutput = "tty";
      StandardError = "journal"; # Without this errors will spam on screen

      # Without these bootlogs will spam on screen
      TTYReset = true;
      TTYVHangup = true;
      TTYVTDisallocate = true;
    };
  };
}
