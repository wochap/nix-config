{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  cfg = config._custom.programs.fi;
in
{
  options._custom.programs.fi = {
    enable = lib.mkEnableOption { };
    package = lib.mkOption {
      type = lib.types.package;
      default = inputs.fi.packages.${pkgs.stdenv.hostPlatform.system}.default;
    };
    openFirewall = lib.mkEnableOption "UDP ports for QUIC (47380-47389) and mDNS (5353)";
    opensnitchRule = lib.mkOption {
      type = lib.types.bool;
      default = config.services.opensnitch.enable;
      description = "Add an OpenSnitch rule that allows fi connections.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedUDPPorts = [
        5353 # mDNS
      ];
      allowedUDPPortRanges = [
        # QUIC
        {
          from = 47380;
          to = 47389;
        }
      ];
    };

    services.opensnitch.rules.allow-fi = lib.mkIf cfg.opensnitchRule {
      name = "allow-fi";
      enabled = true;
      action = "allow";
      duration = "always";
      operator = {
        type = "simple";
        sensitive = false;
        operand = "process.path";
        data = lib.getExe cfg.package;
      };
    };
  };
}
