{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.programs.weeb;
in
{
  options._custom.programs.weeb.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs; [
        ani-cli
      ];
    };
  };
}
