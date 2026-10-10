{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  cfg = config._custom.desktop.quickshell;
  inherit (config._custom.globals)
    themeColorsLight
    themeColorsDark
    preferDark
    configDirectory
    userName
    isSandbox
    ;
  hmConfig = config.home-manager.users.${userName};
  hasPhraseSecret =
    config._custom.security.sops.enable
    && !isSandbox
    && cfg.authDialogs.enable
    && cfg.authDialogs.phraseSecret.sopsFile != null;
  personalSopsFile = ../../../../../secrets-sops/personal.yaml;
  # sops-nix fails the build when a declared key is missing from the file,
  # so the weather location secret is only declared once it has been added
  hasWeatherLocation = lib.hasInfix "\npersonal-weather-location:" (
    "\n" + builtins.readFile personalSopsFile
  );

  quickshell-final = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
  shell-capslock = pkgs.writeScriptBin "shell-capslock" (
    builtins.readFile ./scripts/shell-capslock.sh
  );
  shell-pipewire = pkgs.writeScriptBin "shell-pipewire" (
    builtins.readFile ./scripts/shell-pipewire.sh
  );
  shell-backlight = pkgs.writeScriptBin "shell-backlight" (
    builtins.readFile ./scripts/shell-backlight.sh
  );
  shell-network = pkgs.writeScriptBin "shell-network" (builtins.readFile ./scripts/shell-network.sh);
  shell-bluetooth = pkgs.writeScriptBin "shell-bluetooth" (
    builtins.readFile ./scripts/shell-bluetooth.sh
  );
  shell-idle-inhibit = pkgs.writeScriptBin "shell-idle-inhibit" (
    builtins.readFile ./scripts/shell-idle-inhibit.sh
  );
  shell-idle = pkgs.writeScriptBin "shell-idle" (builtins.readFile ./scripts/shell-idle.sh);
  shell-battery-saver = pkgs.writeScriptBin "shell-battery-saver" (
    builtins.readFile ./scripts/shell-battery-saver.sh
  );
  shell-powerprofiles = pkgs.writeScriptBin "shell-powerprofiles" (
    builtins.readFile ./scripts/shell-powerprofiles.sh
  );
  shell-lock = pkgs.writeScriptBin "shell-lock" (builtins.readFile ./scripts/shell-lock.sh);
  shell-steam-icons = pkgs.writeScriptBin "shell-steam-icons" (
    builtins.readFile ./scripts/shell-steam-icons.sh
  );
  shell-theme = pkgs.writeScriptBin "shell-theme" (builtins.readFile ./scripts/shell-theme.sh);
  shell-recorder = pkgs.writeScriptBin "shell-recorder" (
    builtins.readFile ./scripts/shell-recorder.sh
  );
  shell-offlinemsmtp = pkgs.writeScriptBin "shell-offlinemsmtp" (
    builtins.readFile ./scripts/shell-offlinemsmtp.sh
  );
  shell-mail = pkgs.writeScriptBin "shell-mail" (builtins.readFile ./scripts/shell-mail.sh);
  shell-wireguard = pkgs.writeScriptBin "shell-wireguard" (
    builtins.readFile ./scripts/shell-wireguard.sh
  );
  mkThemeQuickshell = themeColors: pkgs.writeText "theme.json" (builtins.toJSON themeColors);
  catppuccin-quickshell-light-theme-path = mkThemeQuickshell themeColorsLight;
  catppuccin-quickshell-dark-theme-path = mkThemeQuickshell themeColorsDark;
in
{
  options._custom.desktop.quickshell = {
    enable = lib.mkEnableOption { };
    enableSystemd = lib.mkEnableOption { };
    package = lib.mkOption {
      type = lib.types.package;
      default = quickshell-final;
    };
    # Lock screen rendered by a second, resident quickshell instance
    # (dotfiles/shell/lock.qml), replaces hyprlock
    lock = {
      enable = lib.mkEnableOption { };
      # fprintd in parallel to the password
      fingerprint.enable = lib.mkEnableOption { };
    };
    # Render polkit, gpg, ssh and gnome-keyring prompts in the shell
    # (widgets/AuthPrompt), stock agents stay as fallback
    authDialogs = {
      enable = lib.mkEnableOption { };
      polkit = lib.mkEnableOption { };
      pinentry = lib.mkEnableOption { };
      askpass = lib.mkEnableOption { };
      prompter = lib.mkEnableOption { };
      # anti-spoofing phrase shown on every auth dialog, hidden when unset
      phraseSecret.sopsFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "SOPS file containing the auth dialog phrase.";
      };
      phraseSecret.sopsKey = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "local-auth-phrase";
        description = "Key containing the auth dialog phrase in the SOPS file.";
      };
      # resolved per backend switches, read by modules/nixos/security/*
      active = lib.mkOption {
        type = lib.types.attrsOf lib.types.bool;
        internal = true;
        readOnly = true;
        default =
          let
            isOn = cfg.enable && cfg.enableSystemd && cfg.authDialogs.enable;
          in
          {
            polkit = isOn && cfg.authDialogs.polkit;
            pinentry = isOn && cfg.authDialogs.pinentry;
            askpass = isOn && cfg.authDialogs.askpass;
            prompter = isOn && cfg.authDialogs.prompter;
          };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # sops-nix only notices a missing key at activation, where it aborts
    # installing every secret, fail the build instead
    assertions = lib.optional hasPhraseSecret {
      assertion = lib.hasInfix "\n${cfg.authDialogs.phraseSecret.sopsKey}:" (
        "\n" + builtins.readFile cfg.authDialogs.phraseSecret.sopsFile
      );
      message = "${cfg.authDialogs.phraseSecret.sopsKey} is missing from ${toString cfg.authDialogs.phraseSecret.sopsFile}, add it with `sops` or unset authDialogs.phraseSecret.sopsFile";
    };

    environment.systemPackages = with pkgs; [
      # quickshell deps
      cfg.package
      kdePackages.qt5compat

      # shell deps
      ddcutil # query monitor
      rink # calculator
      wallust # pywall like
      matugen # color generator
    ];

    fonts.packages = with pkgs; [ nixpkgs-unstable.material-symbols ];

    # read by SLockSession.qml (PamContext configs)
    security.pam.services = lib.mkIf cfg.lock.enable (
      {
        # password only: `auth include login` would pull in the pam_fprintd
        # rule nixos adds to every service when fprintd is enabled, and that
        # rule blocks the password check until a finger is scanned
        # (the fingerprint runs in its own context below)
        quickshell-lock = {
          fprintAuth = false;
          unixAuth = true;
        };
      }
      // lib.optionalAttrs cfg.lock.fingerprint.enable {
        quickshell-lock-fprint.text = ''
          auth required ${pkgs.fprintd}/lib/security/pam_fprintd.so
        '';
      }
    );
    services.fprintd.enable = lib.mkIf (cfg.lock.enable && cfg.lock.fingerprint.enable) true;

    # "lat,lon,City", read by SWeather.qml from /run/secrets/personal-weather-location,
    # falls back to IP geolocation when missing
    sops.secrets = lib.mkIf (config._custom.security.sops.enable && !isSandbox) (
      lib.optionalAttrs hasWeatherLocation {
        "personal-weather-location" = {
          owner = userName;
          sopsFile = personalSopsFile;
        };
      }
      # read by SAuth.qml through QS_AUTH_PHRASE_FILE
      // lib.optionalAttrs hasPhraseSecret {
        ${cfg.authDialogs.phraseSecret.sopsKey} = {
          owner = userName;
          mode = "0400";
          sopsFile = cfg.authDialogs.phraseSecret.sopsFile;
        };
      }
    );

    _custom.hm = {
      home.packages =
        with pkgs;
        [
          shell-capslock
          shell-network
          shell-bluetooth
          shell-idle-inhibit
          shell-idle
          shell-powerprofiles
          shell-backlight
          shell-pipewire
          shell-lock
          shell-steam-icons
          shell-theme
          shell-recorder
          shell-offlinemsmtp
          shell-mail
          shell-wireguard
          shell-battery-saver
        ]
        ++ lib.optional cfg.authDialogs.enable pkgs._custom.shell-auth;

      xdg.configFile = {
        "quickshell/shell".source = lib._custom.relativeSymlink configDirectory ./dotfiles/shell;
        "quickshell/theme.json" = {
          source =
            if preferDark then
              catppuccin-quickshell-dark-theme-path
            else
              catppuccin-quickshell-light-theme-path;
          force = true;
        };
        "quickshell/theme-light.json".source = catppuccin-quickshell-light-theme-path;
        "quickshell/theme-dark.json".source = catppuccin-quickshell-dark-theme-path;
      };

      # Install custom icon theme
      xdg.dataFile."icons/Reversal-Extra".source = "${inputs.reversal-extra}";

      systemd.user.services.shell = lib.mkIf cfg.enableSystemd (
        lib._custom.mkWaylandService {
          Unit = {
            Description = "Flexible toolkit for making desktop shells with QtQuick, for Wayland and X11";
            Documentation = "https://github.com/quickshell-mirror/quickshell";
          };
          Service = {
            Environment = [
              # NOTE: this or use `dbus-update-activation-environment --systemd <env_var_name>`
              # "TIMEWARRIORDB=${hmConfig.home.sessionVariables.TIMEWARRIORDB}"
            ]
            # SAuth.qml registers the polkit agent only when set, two agents race
            ++ lib.optional cfg.authDialogs.active.polkit "QS_AUTH_POLKIT=1"
            # SAuth.qml shows the fingerprint hint on polkit dialogs only when
            # polkit-1 runs pam_fprintd
            ++ lib.optional (
              cfg.authDialogs.active.polkit
              && config.services.fprintd.enable
              && (config.security.pam.services.polkit-1.fprintAuth or false)
            ) "QS_AUTH_FPRINT=1"
            ++ lib.optional hasPhraseSecret "QS_AUTH_PHRASE_FILE=${
              config.sops.secrets.${cfg.authDialogs.phraseSecret.sopsKey}.path
            }";
            PassEnvironment = [ "HYPRLAND_INSTANCE_SIGNATURE" ];
            ExecStart = "${quickshell-final}/bin/quickshell -p ${hmConfig.xdg.configHome}/quickshell/shell";
            Restart = "on-failure";
            KillMode = "mixed";
          };
        }
      );

      # resident lock instance, `shell-lock --lock` asks it to lock over ipc
      systemd.user.services.shell-lock = lib.mkIf (cfg.enableSystemd && cfg.lock.enable) (
        lib._custom.mkWaylandService {
          Unit = {
            Description = "Quickshell lock screen";
            Documentation = "https://github.com/quickshell-mirror/quickshell";
          };
          Service = {
            Environment = lib.optional cfg.lock.fingerprint.enable "QS_LOCK_FPRINT=1";
            PassEnvironment = [ "HYPRLAND_INSTANCE_SIGNATURE" ];
            ExecStart = "${quickshell-final}/bin/quickshell -p ${hmConfig.xdg.configHome}/quickshell/shell/lock.qml";
            # a dead locker leaves the session locked with nothing to unlock it
            Restart = "always";
            RestartSec = 1;
            KillMode = "mixed";
          };
        }
      );

      # gnome-keyring system prompter, owns its D-Bus name only while the
      # shell auth socket exists so gcr-prompter takes over otherwise
      systemd.user.services.shell-auth-prompter = lib.mkIf cfg.authDialogs.active.prompter (
        lib._custom.mkWaylandService {
          Unit.Description = "Quickshell gnome-keyring prompter";
          Service = {
            ExecStart = "${lib.getExe pkgs._custom.shell-auth} prompter";
            Restart = "always";
            RestartSec = 1;
          };
        }
      );
    };
  };
}
