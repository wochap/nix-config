{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.startx;
  userName = config._userName;
in {
  options._custom.startx = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    services.xserver.displayManager.lightdm.enable = lib.mkForce false;

    services.xserver.displayManager.startx.enable = true;

    home-manager.users.${userName} = {
      programs.zsh.initExtraFirst = ''
        if [[ -z "$DISPLAY" ]] && [[ $(tty) = /dev/tty1 ]]; then
          exec startx
        fi
      '';

      home.file = {
        ".xinitrc".text = ''
          [ -f ~/.xsession ] && . ~/.xsession

        '';

      };
    };
  };
}
