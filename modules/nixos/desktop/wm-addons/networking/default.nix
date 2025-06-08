{ config, lib, pkgs, ... }:

let cfg = config._custom.desktop.networking;
in {
  options._custom.desktop.networking.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.user.extraGroups = [ "networkmanager" ];

    environment = {
      systemPackages = with pkgs; [
        impala
        iw
        wireless-regdb
        zbar # scan wifi QR codes
        wireguard-tools # wg-quick
      ];

      shellAliases.wtui = "impala";
    };

    networking = {
      enableIPv6 = false;

      # Disable wpa_supplicant
      wireless.enable = false;

      wireless.iwd = {
        enable = true;
        settings = {
          # MAC address randomization
          General = {
            AddressRandomization = "once";
            AddressRandomizationRange = "full";
            EnableNetworkConfiguration = true;
          };
          Network.EnableIPv6 = false;
          Settings.AutoConnect = true;
        };
      };

      # Enable NetworkManager
      networkmanager = {
        enable = true;
        # increase boot speed
        wifi.backend = "iwd";
      };

      nameservers = [ "1.1.1.1" "1.0.0.1" "8.8.8.8" "8.8.4.4" ];
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
        ];
      };
    };

    hardware.wirelessRegulatoryDatabase = true;
  };
}
