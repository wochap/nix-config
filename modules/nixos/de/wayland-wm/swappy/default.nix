{ config, pkgs, lib, ... }:

let cfg = config._custom.waylandWm;
in {
  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs;
        [
          swappy # image editor
        ];
    };

    _custom.hm = { xdg.configFile."swappy/config".source = ./dotfiles/config; };
  };
}
