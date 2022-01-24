{ config, pkgs, lib, ... }:

let userName = config._userName;
in {
  config = {
    environment = {
      etc = {
        "sway/borders".source = ./assets/borders;
        "scripts/sway-lock.sh".source = ./scripts/sway-lock.sh;
      };
    };

    home-manager.users.${userName} = {
      wayland.windowManager.sway = {
        enable = true;
        wrapperFeatures.gtk = true;
        systemdIntegration = true;
        swaynag.enable = true;
        xwayland = true;
        extraConfig = ''
          ${builtins.readFile ./dotfiles/config.sh}
        '';
        # extraOptions = [ "--unsupported-gpu" ];
      };
    };
  };
}
