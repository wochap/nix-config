{
  config,
  lib,
  ...
}:

let
  cfg = config._custom.services.tailscale;
in
{
  options._custom.services.tailscale = {
    enable = lib.mkEnableOption { };
    loginServer = lib.mkOption {
      type = lib.types.str;
      # TODO: replace with real headscale domain
      default = "https://hs.example.com";
    };
    sshOnlyTailnet = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      openFirewall = true;
      useRoutingFeatures = "client";
      extraUpFlags = [ "--login-server=${cfg.loginServer}" ];
    };

    networking.firewall.checkReversePath = "loose";
    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ];
    services.openssh.openFirewall = lib.mkIf cfg.sshOnlyTailnet false;

    # DoT/strict DNSSEC break MagicDNS (100.100.100.100, unsigned names)
    services.resolved.settings.Resolve = lib.mkIf config.services.resolved.enable {
      DNSOverTLS = lib.mkForce "opportunistic";
      DNSSEC = lib.mkForce "allow-downgrade";
    };
  };
}
