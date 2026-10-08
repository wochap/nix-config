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
    ];
    runtimeEnv = {
      REMOTE_DISPLAY_PROVIDERS = ./scripts/providers;
      REMOTE_DISPLAY_OUTPUT = streamOutput;
    };
    text = builtins.readFile ./scripts/remote-display.sh;
    meta.description = "Fit the desktop to a Sunshine client's monitor and restore it afterwards";
  };

  hostsFile = pkgs.writeText "remote-desktop-hosts.json" (
    builtins.toJSON (
      lib.mapAttrs (_: host: {
        inherit (host)
          address
          app
          scale
          maxFps
          ;
      }) cfg.client.hosts
    )
  );

  remote-desktop-connect = pkgs.writeShellApplication {
    name = "remote-desktop";
    runtimeInputs = with pkgs; [
      cage
      coreutils
      gnused
      jq
      moonlight-qt
      openssh
      wlr-randr
    ];
    runtimeEnv.REMOTE_HOSTS_FILE = hostsFile;
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

  # base port 47989, offsets from the nixpkgs sunshine module
  sunshinePorts = offsets: map (offset: sunshineCfg.settings.port + offset) offsets;
in
{
  options._custom.services.remote-desktop = {
    host = {
      enable = lib.mkEnableOption "streaming this host's desktop to Moonlight clients (Sunshine)";
      lanInterface = lib.mkOption {
        type = lib.types.nonEmptyStr;
        description = "Only interface where Sunshine ports are open.";
      };
      app = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "Desktop";
        description = "Name of the Sunshine application clients start.";
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
          lib.types.submodule {
            options = {
              address = lib.mkOption {
                type = lib.types.nonEmptyStr;
                description = "Sunshine host, also the ssh destination for remote-display.";
              };
              commandName = lib.mkOption {
                type = lib.types.nullOr lib.types.nonEmptyStr;
                default = null;
                description = "Extra command that runs `remote-desktop <name>`.";
              };
              app = lib.mkOption {
                type = lib.types.nonEmptyStr;
                default = "Desktop";
                description = "Sunshine application to start, the host's `host.app`.";
              };
              scale = lib.mkOption {
                type = lib.types.numbers.positive;
                default = 1;
                description = "Scale the host uses on the streamed output, set to this monitor's scale.";
              };
              maxFps = lib.mkOption {
                type = lib.types.ints.positive;
                default = 120;
              };
            };
          }
        );
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.host.enable {
      environment.systemPackages = [ remote-display ];

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
        };
        applications.apps = [
          {
            name = cfg.host.app;
            prep-cmd = [
              {
                do = "";
                # last resort, Sunshine keeps the app running after a client
                # drops, so this only runs on quit or on the next launch
                undo = "${lib.getExe remote-display} restore";
              }
            ];
            auto-detach = "true";
          }
        ];
      };

      networking.firewall.interfaces.${cfg.host.lanInterface} = {
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
      };

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

      systemd.user.services.sunshine.serviceConfig.ExecStartPre =
        lib.mkIf (cfg.host.credentials.sopsFile != null)
          (
            pkgs.writeShellScript "sunshine-creds" ''
              ${lib.getExe sunshineCfg.package} --creds \
                "$(cat ${config.sops.secrets.${cfg.host.credentials.userKey}.path})" \
                "$(cat ${config.sops.secrets.${cfg.host.credentials.passwordKey}.path})"
            ''
          );
    })

    (lib.mkIf cfg.client.enable {
      environment.systemPackages = [
        pkgs.moonlight-qt
        remote-desktop-connect
        completions
      ]
      ++ aliases;
    })
  ];
}
