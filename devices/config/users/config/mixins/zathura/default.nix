{ config, pkgs, lib, ... }:

let
  userName = config._userName;
in
{
  config = {
    environment.systemPackages = with pkgs; [
      zathura # PDF viewer
    ];

    home-manager.users.${userName} = {
      home.sessionVariables = {
        READER = "zathura";
      };

      home.file = {
        ".config/zathura/zathurarc".source = ./dotfiles/zathurarc;
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
