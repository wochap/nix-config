{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config._custom.desktop.networking;
  inherit (config._custom.globals) isSandbox userName;
in
{
  options._custom.desktop.networking = {
    enable = lib.mkEnableOption { };
    enableWifi = lib.mkEnableOption { };
    enableLocalSend = lib.mkEnableOption { };
    enablePixieCore = lib.mkEnableOption { };
    enableWol = lib.mkEnableOption { };
    enableOpenSnitch = lib.mkEnableOption "OpenSnitch application firewall";
    userUnitsOnConnect = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "lieer-personal.service"
        "vdirsyncer.service"
      ];
      description = ''
        Systemd user units to start whenever NetworkManager brings up a
        connection. This lets network-bound services run immediately after
        boot, resume, or reconnect instead of waiting for their next timer.
        Nothing is started when the user's systemd manager is not running.
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      _custom.user.extraGroups = [ "networkmanager" ];

      networking = {
        nameservers = [
          "1.1.1.1"
          "1.0.0.1"
          "8.8.8.8"
          "8.8.4.4"
        ];
        enableIPv6 = false;
      };
    })

    (lib.mkIf (cfg.enable && isSandbox) {
      networking.firewall.enable = false;
    })

    (lib.mkIf (cfg.enable && (!isSandbox)) {
      environment = {
        systemPackages =
          with pkgs;
          [
            wakeonlan
          ]
          ++ lib.optionals cfg.enableWifi [
            nixpkgs-unstable.impala
            iw
            wireless-regdb
            wireguard-tools # wg-quick
            zbar # scan wifi QR codes
          ];

        shellAliases.wtui = lib.mkIf cfg.enableWifi "impala";
      };

      # enable systemd-resolved
      services.resolved = {
        enable = true;
        # configure systemd-resolved for DoT and DNSSEC
        settings.Resolve = {
          DNSOverTLS = "true";
          DNSSEC = "true";
        };
      };
      networking.resolvconf.enable = false;

      networking = {
        # Disable wpa_supplicant
        wireless.enable = false;

        wireless.iwd = {
          enable = cfg.enableWifi;
          settings = {
            # MAC address randomization
            General = {
              AddressRandomization = "once";
              AddressRandomizationRange = "full";
              EnableNetworkConfiguration = true;
            };
            Scan = {
              DisablePeriodicScan = true;
              DisableHE = true;
            };
            Network = {
              EnableIPv6 = false;
              NameResolvingService = "systemd";
            };
            Settings.AutoConnect = true;
          };
        };

        # Enable NetworkManager
        networkmanager = {
          enable = true;
          # increase boot speed
          wifi.backend = lib.mkIf cfg.enableWifi "iwd";
        };

        firewall = {
          enable = true;
          allowPing = true;
          allowedTCPPortRanges = [
            # servers
            {
              from = 8080;
              to = 8090;
            }
            {
              from = 3000;
              to = 3010;
            }
            # ?
            {
              from = 19000;
              to = 19020;
            }
            # vite
            {
              from = 5173;
              to = 5179;
            }
          ];
          allowedTCPPorts = [
            # 20 # FTP (File Transfer Protocol)
            # 22 # Secure Shell (SSH)
            # 25 # Simple Mail Transfer Protocol (SMTP)
            # 53 #  Domain Name System (DNS)
            # 80 # Hypertext Transfer Protocol (HTTP)
            # 110 # Post Office Protocol (POP3)
            # 143 # Internet Message Access Protocol (IMAP)
            443 # HTTP Secure (HTTPS)

            3333
            4444
            8000

            4000
            9099
            5000
            5001

            # se surveys
            5555
            10016
            9005
            10011

            # se layout-editor
            5601

            # se maps
            5003
            11001
          ]
          ++ lib.optionals cfg.enablePixieCore [
            # TCP 8086 is the custom HTTP port you chose for Pixiecore
            8086
          ];
          allowedUDPPorts =
            [ ]
            ++ lib.optionals cfg.enablePixieCore [
              67 # DHCP server port
              69 # TFTP port (for the initial iPXE bootloader)
              4011 # ProxyDHCP port (Pixiecore's magic trick)
            ]
            ++ lib.optionals cfg.enableWol [ 9 ];
        };
      };

      hardware.wirelessRegulatoryDatabase = true;

      # service discovery, airplay, chromecast, vnc, etc
      services.avahi.enable = true;

      programs.localsend = lib.mkIf cfg.enableLocalSend {
        enable = true;
        openFirewall = true;
      };
    })

    (lib.mkIf (cfg.enable && cfg.userUnitsOnConnect != [ ]) {
      networking.networkmanager.dispatcherScripts = [
        {
          type = "basic";
          source = pkgs.writeShellScript "start-user-units-on-connect" ''
            # NetworkManager passes the interface as $1 and the action as $2.
            [ "$2" = "up" ] || exit 0

            uid=$(${pkgs.coreutils}/bin/id -u ${lib.escapeShellArg userName}) || exit 0
            runtime="/run/user/$uid"

            # No logged-in user manager means there is nothing to start yet.
            [ -S "$runtime/bus" ] || exit 0

            export XDG_RUNTIME_DIR="$runtime"
            export DBUS_SESSION_BUS_ADDRESS="unix:path=$runtime/bus"
            ${pkgs.util-linux}/bin/runuser -u ${lib.escapeShellArg userName} -- \
              ${pkgs.systemd}/bin/systemctl --user start --no-block \
                ${lib.concatStringsSep " " (map lib.escapeShellArg (lib.unique cfg.userUnitsOnConnect))}
          '';
        }
      ];
    })

    (lib.mkIf (cfg.enable && cfg.enableOpenSnitch) {
      services.opensnitch.enable = true;
      environment.systemPackages = [ pkgs.opensnitch-ui ];
    })
  ];
}
