{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.services.ai;
  supertonic-speak = pkgs.writeScriptBin "supertonic-speak" (builtins.readFile ./supertonic-speak.sh);
  supertonic-clipboard = pkgs.writeScriptBin "supertonic-clipboard" (
    builtins.readFile ./supertonic-clipboard.sh
  );
in
{
  config = lib.mkIf (cfg.enable && cfg.enableSupertonic) {
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
          ExecStart = "${lib.getExe pkgs._custom.supertonic} serve --host 127.0.0.1 --port 7788";
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
