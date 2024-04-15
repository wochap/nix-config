{ config, lib, ... }:

let cfg = config._custom.desktop.networking;
in {
  options._custom.desktop.networking.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.user.extraGroups = [ "networkmanager" ];

    networking = {
      enableIPv6 = false;

      # Disable wpa_supplicant
      wireless.enable = lib.mkForce false;

      # Enable NetworkManager
      networkmanager.enable = true;
      nameservers = [ "1.1.1.1" "1.0.0.1" "8.8.8.8" "8.8.4.4" ];
      firewall = {
        enable = true;
        allowPing = true;
        allowedTCPPortRanges = [
          {
            from = 8080;
            to = 8090;
          }
          {
            from = 3000;
            to = 3010;
          }
          {
            from = 19000;
            to = 19020;
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
        ];
      };
    };
  };
}
