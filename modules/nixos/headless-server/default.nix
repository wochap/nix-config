{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.headless-server;
in
{
  options._custom.headless-server.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    services.xserver.displayManager.lightdm.enable = lib.mkForce false;
    environment.systemPackages =
      with pkgs;
      [ ]
      ++ lib.optionals (!config._custom.programs.kitty.enable) [ kitty.terminfo ]
      ++ lib.optionals (!config._custom.programs.foot.enable) [ foot.terminfo ];
  };
}
