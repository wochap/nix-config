{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.tinyweb;

  siteModule = {
    options = {
      port = lib.mkOption {
        type = lib.types.port;
        description = "Port the site listens on.";
      };
      root = lib.mkOption {
        type = lib.types.str;
        description = "Directory to serve.";
      };
      index = lib.mkOption {
        type = lib.types.str;
        default = "index.html";
        description = "Index file name.";
      };
      openFirewall = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to open the site's port in the firewall.";
      };
    };
  };

  sites = lib.attrValues cfg.sites;
  ports = map (s: s.port) sites;
  duplicates = lib.unique (lib.filter (p: lib.count (q: q == p) ports > 1) ports);
in
{
  options.services.tinyweb = {
    enable = lib.mkEnableOption "tinyweb";
    package = lib.mkPackageOption pkgs "darkhttpd" { };
    sites = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule siteModule);
      default = { };
      description = "Sites to serve, one service per site.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = duplicates == [ ];
        message = "services.tinyweb: duplicate port(s) ${lib.concatMapStringsSep ", " toString duplicates}";
      }
    ];

    environment.systemPackages = [ cfg.package ];

    systemd.services = lib.mapAttrs' (
      name: site:
      lib.nameValuePair "tinyweb-${name}" {
        description = "tinyweb site ${name}";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        serviceConfig = {
          ExecStart = "${lib.getExe cfg.package} ${site.root} --port ${toString site.port} --index ${site.index}";
          DynamicUser = true;
          Restart = "on-failure";
        };
      }
    ) cfg.sites;

    networking.firewall.allowedTCPPorts = map (s: s.port) (lib.filter (s: s.openFirewall) sites);
  };
}
