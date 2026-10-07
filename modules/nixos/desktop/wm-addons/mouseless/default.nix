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

    _custom.hm = {
      # gsettings toolkit-accessibility, required by GTK3 apps
      dconf.settings."org/gnome/desktop/interface".toolkit-accessibility = true;

      # Enable org.a11y.Status.IsEnabled on the a11y bus, otherwise GTK3 apps
      # may not register with AT-SPI
      systemd.user.services.a11y-enable = lib._custom.mkGraphicalService {
        # busctl call D-Bus activates org.a11y.Bus, no explicit dependency needed
        Unit.Description = "Enable AT-SPI accessibility bus";
        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.systemd}/bin/busctl --user set-property org.a11y.Bus /org/a11y/bus org.a11y.Status IsEnabled b true";
        };
      };

      # systemd.user.services.hintsd = lib._custom.mkWaylandService {
      #   Unit.Description = "Hints daemon";
      #   Service = {
      #     Type = "simple";
      #     ExecStart = "${hints-final}/bin/hintsd";
      #   };
      # };
    };
  };
}
