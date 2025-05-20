{ config, pkgs, lib, ... }:

let
  cfg = config._custom.desktop.mouseless;

  # https://github.com/AlfredoSequeida/hints/wiki/Window-Manager-and-Desktop-Environment-Setup-Guide#x11-general
  hints-rules = pkgs.writeTextFile {
    name = "80-hints.rules";
    text = ''KERNEL=="uinput", GROUP="input", MODE:="0660"'';
    destination = "/etc/udev/rules.d/80-hints.rules";
  };
  hints-final = pkgs._custom.pythonPackages.hints;
in {
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

    services.udev.packages = [ hints-rules ];

    _custom.user.extraGroups = [ "input" ];

    _custom.hm = {
      systemd.user.services.hintsd = lib._custom.mkWaylandService {
        Unit.Description = "Hints daemon";
        Service = {
          Type = "simple";
          ExecStart = "${hints-final}/bin/hintsd";
        };
      };
    };
  };
}
