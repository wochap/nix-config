{ config, lib, ... }:

let cfg = config._custom.desktop.electron-support;
in {
  options._custom.desktop.electron-support.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    # Enable wayland support (electron apps)
    # https://nixos.wiki/wiki/Wayland
    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    _custom.hm.xdg.configFile."electron-flags.conf".text = ''
      --enable-features=UseOzonePlatform
      --ozone-platform=wayland
    '';
  };
}
