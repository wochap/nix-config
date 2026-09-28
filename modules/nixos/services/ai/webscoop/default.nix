{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  cfg = config._custom.services.ai;
  webscoop = inputs.webscoop.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  options._custom.services.ai.enableWebscoop = lib.mkEnableOption { };

  config = lib.mkIf (cfg.enable && cfg.enableWebscoop) {
    environment.systemPackages = [ webscoop ];

    _custom.hm.xdg.configFile."webscoop/config.json".text = builtins.toJSON {
      browser = {
        driver = "patchright";
        channel = "chrome";
        timezone = "America/Panama";
        locale = "en-US";
      };
      profiles.default = "default";
    };
  };
}
