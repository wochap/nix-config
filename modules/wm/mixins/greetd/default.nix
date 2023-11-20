{ config, pkgs, lib, inputs, ... }:

let
  userName = config._userName;
  cfg = config._custom.wm.greetd;
in {
  options._custom.wm.greetd = {
    enable = lib.mkEnableOption { };
    cmd = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.etc."greetd/environments".text = ''
      dwl
      bash
      zsh
    '';

    # Enable automatic login for the user.
    # services.xserver.displayManager.autoLogin.enable = true;
    # services.xserver.displayManager.autoLogin.user = userName;

    # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
    # systemd.services."getty@tty1".enable = false;
    # systemd.services."autovt@tty1".enable = false;

    services.greetd = {
      enable = true;
      settings = {
        # autologin
        # TODO: autologin doesn't unlock gnome keyring
        # initial_session = {
        #   command = cfg.cmd;
        #   user = userName;
        # };
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
