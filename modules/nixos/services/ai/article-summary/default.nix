{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.services.ai;
  article-summary = pkgs.writeShellApplication {
    name = "article-summary";
    runtimeInputs = [ pkgs.python3 ];
    runtimeEnv = {
      RENDERER = ./render.py;
      INJECTOR = ./inject_controls.py;
    };
    text = builtins.readFile ./article-summary.sh;
  };
in
{
  options._custom.services.ai.enableArticleSummary = lib.mkEnableOption { };

  config = lib.mkIf (cfg.enable && cfg.enableArticleSummary) {
    assertions = [
      {
        assertion = cfg.enableOmniRoute;
        message = "_custom.services.ai.enableArticleSummary requires enableOmniRoute.";
      }
    ];

    environment.systemPackages = [ article-summary ];
  };
}
