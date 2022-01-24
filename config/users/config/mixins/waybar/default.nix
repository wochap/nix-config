{ config, pkgs, lib, ... }:

let userName = config._userName;
in {
  config = {
    # environment = {
    #   etc = {
    #     "xdg/waybar/config".source = ./dotfiles/config;
    #     "xdg/waybar/style.css".source = ./dotfiles/style.css;
    #   };
    # };

    home-manager.users.${userName} = {
      xdg.configFile."waybar/config" = {
        source = ./dotfiles/config.json;
        onChange = ''
          ${pkgs.procps}/bin/pkill -u $USER -USR2 waybar || true
        '';
      };

      xdg.configFile."waybar/style.css" = {
        source = ./dotfiles/style.css;
        onChange = ''
          ${pkgs.procps}/bin/pkill -u $USER -USR2 waybar || true
        '';
      };

      programs.waybar = {
        enable = true;
        systemd.enable = true;
      };
    };
  };
}
