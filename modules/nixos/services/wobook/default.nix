{
  config,
  lib,
  inputs,
  ...
}:

let
  cfg = config._custom.services.wobook;
  inherit (config._custom.globals) userName;
in
{
  # System firewall for sync (UDP 47390-47399) and mDNS (UDP 5353).
  imports = [ inputs.wobook.nixosModules.wobook ];

  options._custom.services.wobook = {
    enable = lib.mkEnableOption "wobook local-first bookmarks";
    chromiumExtensionIds = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Ids shown on chrome://extensions after "Load unpacked" of
        `nix build github:wochap/wobook#extension-chromium`. With browsers.enable, non-empty enables
        the Brave and Google Chrome native messaging hosts.
      '';
    };
    # headless always-online peer: relays changes between members that are
    # not online at the same time; sync port only open on tailscale0
    tailnetOnly = lib.mkEnableOption { };
    syncPort = lib.mkOption {
      type = lib.types.nullOr lib.types.port;
      default = if cfg.tailnetOnly then 47390 else null;
      description = ''
        `WOBOOK_SYNC_PORT` (47390-47399), keeps the endpoint peers remember
        stable. null picks the first free port once and persists it.
      '';
    };
  };

  config = {
    # Set unconditionally: openFirewall defaults to true in the upstream module.
    services.wobook.openFirewall = cfg.enable;
    services.wobook.firewallInterfaces = lib.mkIf cfg.tailnetOnly [ "tailscale0" ];

    # wobookd is a user service, keep it running without a login session
    users.users.${userName}.linger = lib.mkIf (cfg.enable && cfg.tailnetOnly) true;

    _custom.hm = lib.mkIf cfg.enable {
      imports = [ inputs.wobook.homeManagerModules.wobook ];

      programs.wobook = {
        enable = true;
        daemon.enable = true;
        fzf.enable = !cfg.tailnetOnly;
        deviceName = config.networking.hostName;
        hooks."pre-add.strip-utm" = "${inputs.wobook}/contrib/hooks/pre-add.strip-utm";
        browsers = lib.mkIf (!cfg.tailnetOnly) {
          firefox.enable = true;
          brave.enable = cfg.chromiumExtensionIds != [ ];
          googleChrome.enable = cfg.chromiumExtensionIds != [ ];
          inherit (cfg) chromiumExtensionIds;
        };
      };

      # Peers are dialed at their remembered tailnet IPs; multicast does not
      # cross the tailnet, so mDNS is useless here
      systemd.user.services.wobookd.Service.Environment =
        lib.optional (cfg.syncPort != null) "WOBOOK_SYNC_PORT=${toString cfg.syncPort}"
        ++ lib.optional cfg.tailnetOnly "WOBOOK_DISCOVERY=off";
    };
  };
}
