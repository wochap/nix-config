{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.services.remote-desktop;
  inherit (config._custom.globals) userName;
  sunshineCfg = config.services.sunshine;

  # Sunshine streams this headless output, remote-display sizes it to the client
  streamOutput = "HEADLESS-2";

  remote-display = pkgs.writeShellApplication {
    name = "remote-display";
    runtimeInputs = with pkgs; [
      config.programs.hyprland.package
      config.systemd.package
      jq
      util-linux
      gnused
      coreutils
      gnugrep
      socat
    ];
    runtimeEnv = {
      REMOTE_DISPLAY_PROVIDERS = ./scripts/providers;
      REMOTE_DISPLAY_OUTPUT = streamOutput;
      REMOTE_DISPLAY_SCALES = builtins.toJSON cfg.host.scales;
    };
    text = builtins.readFile ./scripts/remote-display.sh;
    meta.description = "Fit the desktop to a Sunshine client's monitor and restore it afterwards";
  };

  # one Sunshine app per mode, the client picks the mode by app name
  sunshineApps = [
    {
      name = cfg.host.app;
      mode = "mirror";
    }
    {
      name = "${cfg.host.app} Headless";
      mode = "headless";
    }
  ];

  # Sunshine runs prep commands without a shell, and sets the client's mode
  # in their environment only at launch
  sunshineApply =
    mode:
    pkgs.writeShellScript "remote-display-apply-${mode}" ''
      exec ${lib.getExe remote-display} apply --mode ${mode} \
        --width "$SUNSHINE_CLIENT_WIDTH" --height "$SUNSHINE_CLIENT_HEIGHT" \
        --fps "$SUNSHINE_CLIENT_FPS"
    '';

  hostsFile = pkgs.writeText "remote-desktop-hosts.json" (
    builtins.toJSON (
      lib.mapAttrs (_: host: {
        inherit (host)
          address
          app
          maxFps
          bitrate
          extraArgs
          ;
      }) cfg.client.hosts
    )
  );

  drm-night-light = pkgs.writers.writePython3Bin "drm-night-light" {
    flakeIgnore = [ "E501" ];
  } (builtins.readFile ./scripts/drm-night-light.py);

  local-keys = pkgs.writers.writePython3Bin "remote-desktop-local-keys" {
    libraries = [ pkgs.python3Packages.evdev ];
    flakeIgnore = [ "E501" ];
  } (builtins.readFile ./scripts/local-keys.py);

  remote-desktop-connect = pkgs.writeShellApplication {
    name = "remote-desktop";
    runtimeInputs = with pkgs; [
      cage
      coreutils
      gnused
      jq
      moonlight-qt
      wlr-randr
      drm-night-light
      local-keys
      wireplumber
    ];
    runtimeEnv = {
      REMOTE_HOSTS_FILE = hostsFile;
      REMOTE_NIGHT_LIGHT = if cfg.client.nightLight == null then "" else toString cfg.client.nightLight;
      DRM_NIGHT_LIGHT_LIBDRM = "${pkgs.libdrm}/lib/libdrm.so.2";
    };
    text = builtins.readFile ./scripts/remote-desktop-connect.sh;
    meta.description = "Stream a remote desktop through Moonlight, from a TTY or a Wayland session";
  };

  # remote-desktop <name> under a short name, e.g. laptop-remote
  aliases = lib.mapAttrsToList (
    name: host:
    pkgs.writeShellScriptBin host.commandName ''
      exec ${lib.getExe remote-desktop-connect} ${lib.escapeShellArg name} "$@"
    ''
  ) (lib.filterAttrs (_: host: host.commandName != null) cfg.client.hosts);

  completions = pkgs.runCommand "remote-desktop-completions" { } ''
    mkdir -p $out/share/zsh/site-functions $out/share/bash-completion/completions
    cat > $out/share/zsh/site-functions/_remote-desktop <<'EOF'
    #compdef remote-desktop
    _arguments \
      '1:host:(${lib.concatStringsSep " " (lib.attrNames cfg.client.hosts)})' \
      '2::mode:(mirror headless)' \
      '--resolution[stream resolution]:WxH' \
      '--fps[stream frame rate]:fps' \
      '--backend[display backend outside a compositor]:backend:(cage eglfs)'
    EOF
    cat > $out/share/bash-completion/completions/remote-desktop <<'EOF'
    complete -W "${lib.concatStringsSep " " (lib.attrNames cfg.client.hosts)} mirror headless --resolution --fps --backend" remote-desktop
    EOF
  '';

  localDomain = config._custom.services.web-gate.certificate.meta.domain;

  # Sunshine web UI, base port + 1; clients assume the default base port
  webUiPort = 47990;

  # base port 47989, offsets from the nixpkgs sunshine module
  sunshinePorts = offsets: map (offset: sunshineCfg.settings.port + offset) offsets;
in
{
  options._custom.services.remote-desktop = {
    host = {
      enable = lib.mkEnableOption "streaming this host's desktop to Moonlight clients (Sunshine)";
      interfaces = lib.mkOption {
        type = lib.types.listOf lib.types.nonEmptyStr;
        default = [ ];
        example = [
          "wlan0"
          "tailscale0"
        ];
        description = "Only interfaces where Sunshine ports are open.";
      };
      app = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "Desktop";
        description = "Name of the Sunshine application that mirrors the physical outputs. `<app> Headless` leaves them untouched.";
      };
      scales = lib.mkOption {
        type = lib.types.attrsOf lib.types.numbers.positive;
        default = { };
        example = {
          "3840x2160" = 1.5;
        };
        description = "Scale of the streamed output per client resolution (`WxH`), 1 otherwise. Sunshine sends no client name, so clients with the same resolution share a scale.";
      };
      webUi.subdomain = lib.mkOption {
        type = lib.types.nullOr lib.types.nonEmptyStr;
        default = "sunshine";
        description = "web-gate subdomain for this host's Sunshine web UI (`https://<subdomain>.<certificate domain>`). null disables it.";
      };
      webUi.allowedOrigins = lib.mkOption {
        type = lib.types.listOf lib.types.nonEmptyStr;
        default =
          lib.optional (cfg.host.webUi.subdomain != null) "https://${cfg.host.webUi.subdomain}.${localDomain}"
          ++ [ "https://sunshine-${config.networking.hostName}.${localDomain}" ];
        defaultText = lib.literalExpression ''
          [
            "https://<host.webUi.subdomain>.<certificate domain>"
            "https://sunshine-<hostName>.<certificate domain>" # a client's proxy, client.hosts.<hostName>
          ]
        '';
        description = "Origins Sunshine's CSRF check accepts besides localhost, i.e. the web-gate proxies in front of its web UI.";
      };
      credentials = {
        sopsFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "SOPS file with the Sunshine web UI login, used for pairing. null keeps the login set in the web UI.";
        };
        userKey = lib.mkOption {
          type = lib.types.nonEmptyStr;
          default = "local-sunshine-user";
        };
        passwordKey = lib.mkOption {
          type = lib.types.nonEmptyStr;
          default = "local-sunshine-password";
        };
      };
    };

    client = {
      enable = lib.mkEnableOption "the remote-desktop command, which streams a host's desktop through Moonlight";
      nightLight = lib.mkOption {
        type = lib.types.nullOr lib.types.ints.positive;
        default = null;
        example = 4000;
        description = "Color temperature (K) for `--backend eglfs`, which has no compositor to keep a night light. null follows the local hyprsunset (`hyprctl -i 0 hyprsunset temperature`).";
      };
      hosts = lib.mkOption {
        default = { };
        example = lib.literalExpression ''
          {
            laptop = {
              address = "laptop.local";
              commandName = "laptop-remote";
            };
          }
        '';
        description = "Hosts to control, run as `remote-desktop <name>`.";
        type = lib.types.attrsOf (
          lib.types.submodule (
            { name, ... }:
            {
              options = {
                address = lib.mkOption {
                  type = lib.types.nonEmptyStr;
                  description = "Sunshine host.";
                };
                webUi.subdomain = lib.mkOption {
                  type = lib.types.nullOr lib.types.nonEmptyStr;
                  default = "sunshine-${name}";
                  defaultText = lib.literalExpression ''"sunshine-''${name}"'';
                  description = "web-gate subdomain on this machine for the host's Sunshine web UI. null disables it.";
                };
                commandName = lib.mkOption {
                  type = lib.types.nullOr lib.types.nonEmptyStr;
                  default = null;
                  description = "Extra command that runs `remote-desktop <name>`.";
                };
                app = lib.mkOption {
                  type = lib.types.nonEmptyStr;
                  default = "Desktop";
                  description = "Sunshine application to start in mirror mode, the host's `host.app`. Headless mode starts `<app> Headless`.";
                };
                maxFps = lib.mkOption {
                  type = lib.types.ints.positive;
                  default = 120;
                };
                bitrate = lib.mkOption {
                  type = lib.types.nullOr lib.types.ints.positive;
                  default = 50000;
                  description = "Stream bitrate in Kbps. null lets Moonlight pick from resolution and fps, which looks soft on a desktop.";
                };
                extraArgs = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                  example = [
                    "--video-codec"
                    "HEVC"
                  ];
                  description = "Extra `moonlight stream` arguments.";
                };
              };
            }
          )
        );
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.host.enable {
      assertions = [
        {
          assertion = cfg.host.interfaces != [ ];
          message = "_custom.services.remote-desktop.host.interfaces must list the interfaces clients connect on.";
        }
      ];

      environment.systemPackages = [ remote-display ];

      # https://sunshine.wochap.local, pairing PINs without typing the port
      _custom.services.web-gate.proxies.sunshine = lib.mkIf (cfg.host.webUi.subdomain != null) {
        enable = true;
        inherit (cfg.host.webUi) subdomain;
        publicPort = sunshineCfg.settings.port + 1;
        backendPort = sunshineCfg.settings.port + 1;
        # Sunshine binds all addresses, the web UI is TLS only
        backendScheme = "https";
      };

      services.sunshine = {
        enable = true;
        autoStart = true;
        # wlr capture needs no CAP_SYS_ADMIN, only KMS capture does
        capSysAdmin = false;
        openFirewall = false;
        settings = {
          capture = "wlr";
          # matched by xdg_output name
          output_name = streamOutput;
          csrf_allowed_origins = lib.concatStringsSep "," cfg.host.webUi.allowedOrigins;
          # require encrypted video/audio/control from every client, the LAN
          # default leaves video in the clear
          lan_encryption_mode = 2;
          wan_encryption_mode = 2;
        };
        # Sunshine keeps the app running after a client drops, so undo runs
        # only on quit. A resume skips do, the display keeps its first size.
        applications.apps = map (app: {
          inherit (app) name;
          prep-cmd = [
            {
              do = toString (sunshineApply app.mode);
              undo = "${lib.getExe remote-display} restore";
            }
          ];
          auto-detach = "true";
        }) sunshineApps;
      };

      networking.firewall.interfaces = lib.genAttrs cfg.host.interfaces (_: {
        allowedTCPPorts = sunshinePorts [
          (-5)
          0
          1
          21
        ];
        allowedUDPPorts = sunshinePorts [
          9
          10
          11
          13
          21
        ];
      });

      sops.secrets = lib.mkIf (cfg.host.credentials.sopsFile != null) {
        ${cfg.host.credentials.userKey} = {
          inherit (cfg.host.credentials) sopsFile;
          owner = userName;
        };
        ${cfg.host.credentials.passwordKey} = {
          inherit (cfg.host.credentials) sopsFile;
          owner = userName;
        };
      };

      systemd.user.services.sunshine.serviceConfig = {
        ExecStartPre = lib.mkIf (cfg.host.credentials.sopsFile != null) (
          pkgs.writeShellScript "sunshine-creds" ''
            ${lib.getExe sunshineCfg.package} --creds \
              "$(cat ${config.sops.secrets.${cfg.host.credentials.userKey}.path})" \
              "$(cat ${config.sops.secrets.${cfg.host.credentials.passwordKey}.path})"
          ''
        );
        # Sunshine skips undo when it stops with an app running. "-": the
        # compositor may already be gone on logout
        ExecStopPost = "-${lib.getExe remote-display} restore";
      };
    })

    (lib.mkIf cfg.client.enable {
      # https://sunshine-<name>.wochap.local, each host's web UI from this machine
      _custom.services.web-gate.proxies = lib.mapAttrs' (
        name: host:
        lib.nameValuePair "sunshine-${name}" {
          enable = true;
          inherit (host.webUi) subdomain;
          publicPort = webUiPort;
          backendPort = webUiPort;
          backendHost = host.address;
          backendScheme = "https";
        }
      ) (lib.filterAttrs (_: host: host.webUi.subdomain != null) cfg.client.hosts);

      environment.systemPackages = [
        pkgs.moonlight-qt
        remote-desktop-connect
        completions
      ]
      ++ aliases;
    })
  ];
}
