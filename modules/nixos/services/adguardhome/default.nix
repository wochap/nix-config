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
  options._custom.services.adguardhome = {
    enable = lib.mkEnableOption { };
    # web UI logins, password is a bcrypt hash:
    # nix shell nixpkgs#apacheHttpd -c htpasswd -B -C 10 -n <name>
    users = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            name = lib.mkOption { type = lib.types.str; };
            password = lib.mkOption { type = lib.types.str; };
          };
        }
      );
      default = [ ];
    };
    # not 0.0.0.0, which collides with resolved's stub on 127.0.0.53
    bindHosts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "127.0.0.1" ];
      example = [
        "100.64.0.4"
        "127.0.0.1"
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    services.adguardhome = {
      enable = true;
      openFirewall = false;
      port = 3000;
      settings = {
        dns = {
          # `bind_host` (pre-v0.106) is ignored, this is the live key
          bind_hosts = cfg.bindHosts;
          # Upstream servers
          upstream_dns = [
            "9.9.9.9"
            "149.112.112.112"
          ];
        };
        inherit (cfg) users;
        # replaces lists added in the web UI on every restart, add them here
        filters = [
          {
            id = 1;
            enabled = true;
            name = "AdGuard DNS filter";
            url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
          }
          {
            id = 2;
            enabled = true;
            name = "HaGeZi's Pro Blocklist";
            url = "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/pro.txt";
          }
          {
            id = 3;
            enabled = true;
            name = "HaGeZi's Threat Intelligence Feeds";
            url = "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/tif.txt";
          }
        ];
        querylog = {
          enabled = true;
          file_enabled = true;
          interval = "168h"; # 7 days
        };
        statistics = {
          enabled = true;
          interval = "720h"; # 30 days
        };
      };
    };

    # a tailnet IP in bindHosts only exists once tailscaled is up
    boot.kernel.sysctl."net.ipv4.ip_nonlocal_bind" = 1;
    systemd.services.adguardhome = {
      after = [ "tailscaled.service" ];
      wants = [ "tailscaled.service" ];
    };

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
