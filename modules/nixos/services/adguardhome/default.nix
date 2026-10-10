{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config._custom.services.adguardhome;
in
{
  options._custom.services.adguardhome.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    services.adguardhome = {
      enable = true;
      openFirewall = false;
      port = 3000;
      settings = {
        dns = {
          # This ensures AdGuard Home listens for DNS queries on port 53
          bind_host = "0.0.0.0";
          # Upstream servers
          upstream_dns = [
            "9.9.9.9"
            "149.112.112.112"
          ];
        };
      };
    };

    # resolved's stub on 127.0.0.53:53 blocks bind_host 0.0.0.0:53
    services.resolved.enable = false;

    # DNS and web UI only reachable over the tailnet
    networking.firewall.interfaces.tailscale0 = {
      allowedTCPPorts = [
        53
        3000
      ];
      allowedUDPPorts = [ 53 ];
    };
  };
}
