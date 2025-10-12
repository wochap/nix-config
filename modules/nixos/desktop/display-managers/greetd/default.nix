{ config, pkgs, lib, ... }:

let
  cfg = config._custom.desktop.greetd;
  inherit (config._custom.globals) userName;
  sessionsBasePath = config.services.displayManager.sessionData.desktops;
  run-desktop = pkgs.writers.writePerlBin "run-desktop" {
    libraries = with pkgs.perlPackages; [ ConfigINI ];
  } (lib.fileContents (pkgs.replaceVars ./dotfiles/run-desktop.pl {
    waylandSessionsPath = "${sessionsBasePath}/share/wayland-sessions";
  }));
in {
  options._custom.desktop.greetd = {
    enable = lib.mkEnableOption { };
    enableAutoLogin = lib.mkEnableOption { };
    enablePamAutoLogin = lib.mkEnableOption { };
    enablePamSystemdLoadkey = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    # binaries to whitelist in greetd
    environment = {
      systemPackages = with pkgs; [ run-desktop ];
      etc."greetd/environments".text = ''
        bash
        zsh
        run-desktop
      '';
    };

    services.xserver.displayManager.lightdm.enable = false;

    services.displayManager.autoLogin = {
      enable = true;
      user = userName;
    };

    services.greetd = {
      enable = true;
      settings = {
        terminal.vt = "1";
        restart = !cfg.enableAutoLogin;
        # TODO: greetd autologin doesn't unlock keyring
        # source: https://github.com/viperML/dotfiles/blob/77c91f02baed99bb0e62d9a5d8bb8ed02d50b035/misc/nixos/greetd/default.nix#L27
        initial_session = lib.mkIf cfg.enableAutoLogin {
          command = "${
              lib.getExe run-desktop
            } --silent ${config.services.displayManager.defaultSession}";
          inherit (config.services.displayManager.autoLogin) user;
        };
        default_session = {
          command = ''
            ${
              lib.getExe pkgs.greetd.tuigreet
            } --user-menu --window-padding 2 --remember-session --time --time-format "%a %d %b %H:%M %Y" --sessions "${sessionsBasePath}/share/wayland-sessions" --xsessions "${sessionsBasePath}/share/xsessions"'';
          user = "greeter";
        };
      };
    };
    systemd.services.greetd.serviceConfig.KeyringMode =
      lib.mkIf cfg.enablePamSystemdLoadkey (lib.mkForce "inherit");

    security.pam.services.greetd.rules = {
      password.gnome_keyring.settings.use_authtok = cfg.enablePamSystemdLoadkey;

      auth = {
        # autologin with Pam_autologin
        # docs: https://wiki.archlinux.org/title/Pam_autologin
        autologin = {
          enable = cfg.enablePamAutoLogin;
          order =
            config.security.pam.services.greetd.rules.auth.unix-early.order - 2;
          control = "required";
          modulePath =
            "${pkgs._custom.pam-autologin}/lib/security/pam_autologin.so";
        };

        # unlock keyring using luks passphrase
        systemd_loadkey = {
          enable = cfg.enablePamSystemdLoadkey;
          order =
            config.security.pam.services.greetd.rules.auth.gnome_keyring.order
            - 1;
          control = "optional";
          modulePath = "${pkgs.systemd}/lib/security/pam_systemd_loadkey.so";
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
