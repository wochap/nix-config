{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.desktop.greetd;
  inherit (config._custom.globals) userName;
  sessionsBasePath = config.services.displayManager.sessionData.desktops;
  tuigreetCmd = ''${lib.getExe pkgs.tuigreet} --user-menu --window-padding 2 --remember-session --time --time-format "%a %d %b %H:%M %Y" --sessions "${sessionsBasePath}/share/wayland-sessions" --xsessions "${sessionsBasePath}/share/xsessions"'';
in
{
  options._custom.desktop.greetd = {
    enable = lib.mkEnableOption { };
    enableAutoLogin = lib.mkEnableOption { };
    enableLuksIntegration = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    # binaries to whitelist in greetd
    environment = {
      systemPackages = [ pkgs._custom.run-desktop ];
      etc."greetd/environments".text = ''
        bash
        zsh
        run-desktop
        greetd-autologin
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
        terminal.vt = 1;
        restart = !cfg.enableAutoLogin;
        default_session = {
          command =
            if cfg.enableAutoLogin then
              "${lib.getExe pkgs._custom.greetd-autologin} '${tuigreetCmd}' ${config.services.displayManager.autoLogin.user} env WAYLAND_SESSIONS_PATH=${sessionsBasePath}/share/wayland-sessions ${lib.getExe pkgs._custom.run-desktop} --silent ${config.services.displayManager.defaultSession}"
            else
              tuigreetCmd;
          user = "greeter";
        };
      };
    };
    systemd.services.greetd.serviceConfig.KeyringMode = lib.mkIf cfg.enableLuksIntegration (
      lib.mkForce "inherit"
    );

    # Persist the marker across greetd sessions; /run clears it on reboot.
    systemd.tmpfiles.rules = lib.mkIf cfg.enableAutoLogin [
      "d /run/greetd-autologin 0700 greeter greeter -"
    ];

    security.pam.services.greetd.rules = {
      password.gnome_keyring.settings.use_authtok = cfg.enableLuksIntegration;

      auth = {
        # unlock keyring using luks passphrase
        systemd_loadkey = {
          enable = cfg.enableLuksIntegration;
          order = 10;
          control = "optional";
          modulePath = "${pkgs.systemd}/lib/security/pam_systemd_loadkey.so";
        };

        # permit login if user just presses Enter in tuigreet
        permit = {
          enable = true;
          order = 999;
          control = "sufficient";
          modulePath = "${pkgs.linux-pam}/lib/security/pam_permit.so";
        };
      };
    };

    # HACK: stop printing status messages in tuigreet
    # https://github.com/apognu/tuigreet/issues/68#issuecomment-1192683029
    # https://www.reddit.com/r/NixOS/comments/u0cdpi/tuigreet_with_xmonad_how/
    systemd.services.greetd.serviceConfig = {
      Type = "idle";
      RuntimeDirectory = "greetd";

      StandardInput = "tty";
      # StandardOutput = "journal";
      StandardOutput = "tty";
      StandardError = "journal"; # Without this errors will spam on screen

      # Without these bootlogs will spam on screen
      TTYReset = true;
      TTYVHangup = true;
      TTYVTDisallocate = true;
    };
  };
}
