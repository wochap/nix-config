{ config, pkgs, lib, ... }:

let cfg = config._custom.desktop.kanshi;
in {
  options._custom.desktop.kanshi.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment = { systemPackages = with pkgs; [ kanshi ]; };

    _custom.hm = {
      xdg.configFile."kanshi/config".source = ./dotfiles/config;

      systemd.user.services.kanshi = lib._custom.mkWaylandService {
        Unit = {
          Description = "Dynamic output configuration";
          Documentation = "man:kanshi(1)";
          Requires = "wayland-session.target";
        };
        Service = {
          Type = "simple";
          ExecStart = "${pkgs.kanshi}/bin/kanshi";
          Restart = "always";
        };
      };
    };
  };
}
