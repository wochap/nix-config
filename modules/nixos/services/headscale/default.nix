{
  config,
  lib,
  ...
}:

let
  cfg = config._custom.services.headscale;
in
{
  options._custom.services.headscale = {
    enable = lib.mkEnableOption { };
    domain = lib.mkOption {
      type = lib.types.str;
      example = "hs.example.com";
    };
    baseDomain = lib.mkOption {
      type = lib.types.str;
      example = "tail.example.com";
      description = "MagicDNS suffix, must differ from domain";
    };
    nameservers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      # set per host to the tailnet IP of the node running AdGuard Home
      default = [ "100.64.0.1" ];
    };
  };

  config = lib.mkIf cfg.enable {
    services.headscale = {
      enable = true;
      address = "127.0.0.1";
      port = 8080;
      settings = {
        server_url = "https://${cfg.domain}";
        dns = {
          magic_dns = true;
          base_domain = cfg.baseDomain;
          nameservers.global = cfg.nameservers;
          override_local_dns = true;
        };
        derp.server = {
          enabled = true;
          region_id = 999;
          stun_listen_addr = "0.0.0.0:3478";
        };
        prefixes.v4 = "100.64.0.0/10";
        logtail.enabled = false;
      };
    };

    services.caddy = {
      enable = true;
      virtualHosts.${cfg.domain}.extraConfig = "reverse_proxy 127.0.0.1:8080";
    };

    networking.firewall = {
      allowedTCPPorts = [
        80
        443
      ];
      allowedUDPPorts = [ 3478 ];
    };

    environment.systemPackages = [ config.services.headscale.package ];
  };
}
