{ config, pkgs, lib, ... }:

let
  cfg = config._custom.programs.dolphin;
  dolphin-final = pkgs.kdePackages.dolphin;
in {
  options._custom.programs.dolphin.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      kdePackages.ark # archive manager

      # kcmshell5 to change kde settings on wm
      # e.g. default terminal on dolphin
      kdePackages.kde-cli-tools

      # dolplhin
      dolphin-final
      kdePackages.dolphin-plugins
      kdePackages.kio-extras # thumbnails
      kdePackages.kdegraphics-thumbnailers # thumbnails
      kdePackages.qtimageformats # thumbnails
      kdePackages.ffmpegthumbs # thumbnails
    ];

    _custom.hm = {
      systemd.user.services.dolphin-server = lib._custom.mkWaylandService {
        Unit.Description = "Dolphin file manager";
        Service = {
          Type = "simple";
          ExecStart = "${dolphin-final}/bin/dolphin --daemon";
          KillMode = "process";
        };
      };
    };
  };
}
