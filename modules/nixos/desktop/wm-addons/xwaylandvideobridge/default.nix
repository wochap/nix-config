{ config, pkgs, lib, ... }:

let cfg = config._custom.de.xwaylandvideobridge;
in {
  options._custom.de.xwaylandvideobridge.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ xwaylandvideobridge ];

    _custom.hm = {
      systemd.user.services.xwaylandvideobridge = lib._custom.mkWaylandService {
        Unit = {
          Description =
            "Utility to allow streaming Wayland windows to X applications";
          Documentation = "https://invent.kde.org/system/xwaylandvideobridge";
        };
        Service.ExecStart =
          "${pkgs.xwaylandvideobridge}/bin/xwaylandvideobridge";
      };
    };
  };
}
