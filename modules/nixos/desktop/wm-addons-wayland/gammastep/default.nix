{ config, pkgs, lib, ... }:

let cfg = config._custom.desktop.gammastep;
in {
  options._custom.desktop.gammastep.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ gammastep ];

    _custom.hm = {
      services.gammastep = {
        enable = true;
        latitude = "-12.051408";
        longitude = "-76.922124";
        temperature = {
          day = 4000;
          night = 3700;
        };
      };

      # only start gammastep on wayland wm
      systemd.user.services.gammastep = lib._custom.mkWaylandService {
        # Unit.ConditionEnvironment = lib.mkForce "!XDG_SESSION_DESKTOP=hyprland";
      };
    };
  };
}
