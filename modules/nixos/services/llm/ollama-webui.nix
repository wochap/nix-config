{ config, pkgs, lib, ... }:

with lib;
let cfg = config.services.ollama-webui-lite;
in {
  options = {
    services.ollama-webui-lite = {
      enable = mkEnableOption { };
      package = mkPackageOption pkgs "ollama-webui-lite" { };
      host = mkOption {
        type = types.str;
        default = "localhost";
        example = "0.0.0.0";
      };
      port = mkOption {
        type = types.port;
        default = 11444;
      };
      openFirewall = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.ollama-webui-lite = {
      description = "Ollama WebUI Service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        ExecStart =
          "${cfg.package}/bin/ollama-webui-lite --listen tcp://${cfg.host}:${
            toString cfg.port
          }";
        DynamicUser = "true";
        Type = "simple";
        Restart = "on-failure";
      };
    };

    networking.firewall =
      mkIf cfg.openFirewall { allowedTCPPorts = [ cfg.port ]; };
  };
}
