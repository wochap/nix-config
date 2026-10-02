{ config, lib, ... }:
let
  cfg = config.services.greeter;
in
{
  options.services.greeter = {
    enable = lib.mkEnableOption "the greeter service";
    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Port the greeter listens on.";
    };
    message = lib.mkOption {
      type = lib.types.str;
      default = "Hello";
      description = "Greeting message.";
    };
    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to open the port in the firewall.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.etc."greeter.conf".text = ''
      port=${toString cfg.port}
      message=${cfg.message}
    '';
    networking.firewall.allowedTCPPorts = lib.optionals cfg.openFirewall [ cfg.port ];
  };
}
