{ config, pkgs, lib, ... }:

let cfg = config._custom.wm.plymouth;
in {
  options._custom.wm.plymouth = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {

    boot.plymouth = {
      enable = true;
      font = "${pkgs.iosevka}/share/fonts/truetype/iosevka-regular.ttf";
      themePackages = with pkgs;
        [ (catppuccin-plymouth.override { variant = "mocha"; }) ];
      theme = "catppuccin-mocha";
    };

    boot.initrd.systemd.enable = true;
    boot.kernelParams = [ "quiet" ];
  };
}

