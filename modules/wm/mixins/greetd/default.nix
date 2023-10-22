{ config, pkgs, lib, inputs, ... }:

let cfg = config._custom.wm.greetd;
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
      zsh
    '';

    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = ''
            ${pkgs.greetd.tuigreet}/bin/tuigreet --user-menu --window-padding 2 --time --remember --cmd "${cfg.cmd}"'';
          user = "greeter";
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
