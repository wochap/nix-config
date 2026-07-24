{ config, inputs, lib, pkgs, ... }:

{
  services.adguardhome = {
    enable = true;
    openFirewall = true;
    port = 3000;
    settings = {
      dns = {
        # This ensures AdGuard Home listens for DNS queries on port 53
        bind_host = "0.0.0.0";
        # Upstream servers
        upstream_dns = [ "9.9.9.9" "149.112.112.112" ];
      };
    };
  };

  # If you need to manually manage the firewall, ensure these are open:
  # networking.firewall.allowedTCPPorts = [ 3000 53 ];
  # networking.firewall.allowedUDPPorts = [ 53 ];
}

