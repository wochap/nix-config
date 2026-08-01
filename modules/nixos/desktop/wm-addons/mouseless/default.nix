{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.desktop.mouseless;

  hints-final = pkgs._custom.pythonPackages.hints;
in
{
  options._custom.desktop.mouseless.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ hints-final ];

    environment.sessionVariables = {
      ACCESSIBILITY_ENABLED = "1";
      # GTK_MODULES = "gail:atk-bridge";
      OOO_FORCE_DESKTOP = "gnome";
      GNOME_ACCESSIBILITY = "1";
      QT_ACCESSIBILITY = "1";
      QT_LINUX_ACCESSIBILITY_ALWAYS_ON = "1";
    };

    services.gnome.at-spi2-core.enable = true;

    _custom.user.extraGroups = [ "input" ];

    # _custom.hm = {
    #   systemd.user.services.hintsd = lib._custom.mkWaylandService {
    #     Unit.Description = "Hints daemon";
    #     Service = {
    #       Type = "simple";
    #       ExecStart = "${hints-final}/bin/hintsd";
    #     };
    #   };
    # };
  };
}
