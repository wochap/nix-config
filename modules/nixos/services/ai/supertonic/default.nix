{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.services.ai;
  inherit (pkgs._custom) wochap-ssc;
  inherit (config._custom.globals) userName;
  supertonic-speak = pkgs.writeScriptBin "supertonic-speak" (builtins.readFile ./supertonic-speak.sh);
  supertonic-clipboard = pkgs.writeScriptBin "supertonic-clipboard" (
    builtins.readFile ./supertonic-clipboard.sh
  );
in
{
  options._custom.services.ai.enableSupertonic = lib.mkEnableOption { };

  config = lib.mkIf (cfg.enable && cfg.enableSupertonic) {
    _custom.services.web-proxies.supertonic = {
      enable = true;
      subdomain = "supertonic";
      publicPort = 7788;
      backendPort = 7789;
      lazy = true;
      serviceScope = "user";
      inherit userName;
    };

    _custom.hm = {
      home.packages = [
        pkgs._custom.supertonic
        supertonic-speak
        supertonic-clipboard
      ];

      systemd.user.services.supertonic = {
        Unit = {
          Description = "Supertonic text-to-speech service";
          Documentation = "https://supertone-inc.github.io/supertonic-py/quickstart/#local-server";
          PartOf = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = "${lib.getExe pkgs._custom.supertonic} serve --host ${wochap-ssc.meta.address} --port ${toString config._custom.services.web-proxies.supertonic.backendPort}";
          Restart = "on-failure";
          RestartSec = 2;
          # PERF: test those env vars
          # "SUPERTONIC_INTRA_OP_THREADS=8"
          # "SUPERTONIC_INTER_OP_THREADS=8"
          Environment = [ "HF_HUB_DISABLE_TELEMETRY=1" ];
        }
        // lib._custom.userServiceHardening
        // {
          ProtectHome = "tmpfs";
          BindPaths = [
            "%h/.cache/supertonic3"
            "%h/.cache/huggingface"
          ];
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
            "AF_UNIX"
          ];
        };
      };
    };
  };
}
