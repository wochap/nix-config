{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config._custom.services.webhook;
  proxy = config._custom.services.web-gate.proxies.webhook;
  inherit (pkgs._custom) wochap-ssc;
  inherit (config._custom.globals) userName;
  json = pkgs.formats.json { };
  hooksFile = json.generate "webhook-hooks.json" cfg.hooks;
in
{
  options._custom.services.webhook = {
    enable = lib.mkEnableOption { };
    hooks = lib.mkOption {
      type = lib.types.listOf json.type;
      default = [ ];
      description = ''
        Hook definitions, see
        https://github.com/adnanh/webhook/blob/master/docs/Hook-Definition.md.
        A hook with id "foo/bar" is served at https://webhook.<domain>/foo/bar.
      '';
    };
    environment = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "FOO=bar" ];
      description = "Extra Environment= entries for the webhook user service.";
    };
  };

  config = lib.mkIf cfg.enable {
    _custom.services.web-gate.proxies.webhook = {
      enable = true;
      subdomain = "webhook";
      publicPort = 9099;
      backendPort = 9100;
      lazy = true;
      serviceScope = "user";
      inherit userName;
    };

    # Hooks often drive things on the user's session (e.g. a browser
    # window), so this is a user service instead of a sandboxed system one.
    _custom.hm.systemd.user.services.webhook = {
      Unit = {
        Description = "Webhook server";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        # empty urlprefix serves hooks at /<id> instead of /hooks/<id>
        ExecStart = "${lib.getExe pkgs.webhook} -hooks ${hooksFile} -urlprefix \"\" -ip ${wochap-ssc.meta.address} -port ${toString proxy.backendPort} -verbose";
        Restart = "on-failure";
        RestartSec = 2;
        Environment = [
          "PATH=/run/current-system/sw/bin:/etc/profiles/per-user/${userName}/bin"
        ]
        ++ cfg.environment;
      };
    };
  };
}
