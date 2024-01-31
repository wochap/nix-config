{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.gui.zathura;
  userName = config._userName;
in {
  options._custom.gui.zathura = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      [
        zathura # PDF viewer
      ];

    home-manager.users.${userName} = {
      home.sessionVariables = { READER = "zathura"; };

      xdg.configFile = {
        "zathura/catppuccin-mocha".source =
          "${inputs.catppuccin-zathura}/src/catppuccin-mocha";
        "zathura/zathurarc".source = ./dotfiles/zathurarc;
      };

      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "application/pdf" = [ "org.pwmt.zathura.desktop" ];
        };
        associations.added = {
          "application/pdf" = [ "org.pwmt.zathura.desktop" ];
        };
      };
    };
  };
}
