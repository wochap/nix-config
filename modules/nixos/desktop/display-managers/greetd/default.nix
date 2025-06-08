{ config, pkgs, lib, ... }:

let
  cfg = config._custom.desktop.greetd;
  inherit (config._custom.globals) userName;
  desktopsPath = config.services.displayManager.sessionData.desktops;
in {
  options._custom.desktop.greetd = {
    enable = lib.mkEnableOption { };
    enableAutoLogin = lib.mkEnableOption { };
    enablePamAutoLogin = lib.mkEnableOption { };
    autoLoginCmd = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
  };

  config = lib.mkIf cfg.enable {
    # binaries to whitelist in greetd
    environment.etc."greetd/environments".text = ''
      bash
      zsh
    '';

    services.xserver.displayManager.lightdm.enable = false;

    services.greetd = {
      enable = true;
      settings = {
        terminal.vt = "1";
        restart = true;
        # NOTE: greetd autologin doesn't unlock gnome keyring
        # NOTE: autologin inspiration https://github.com/viperML/dotfiles/blob/77c91f02baed99bb0e62d9a5d8bb8ed02d50b035/misc/nixos/greetd/default.nix#L27
        initial_session = lib.mkIf cfg.enableAutoLogin {
          command = cfg.autoLoginCmd;
          user = userName;
        };
        default_session = {
          command = ''
            ${
              lib.getExe pkgs.greetd.tuigreet
            } --user-menu --window-padding 2 --remember-session --time --time-format "%a %d %b %H:%M %Y" --sessions "${desktopsPath}/share/wayland-sessions" --xsessions "${desktopsPath}/share/xsessions"'';
          user = userName;
        };
      };
    };

    # autologin with Pam_autologin
    # docs: https://wiki.archlinux.org/title/Pam_autologin
    security.pam.services.greetd.rules.auth.autologin =
      lib.mkIf cfg.enablePamAutoLogin {
        enable = true;
        order = config.security.pam.services.greetd.rules.auth.unix-early.order
          - 1;
        control = "required";
        modulePath =
          "${pkgs._custom.pam-autologin}/lib/security/pam_autologin.so";
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
