{ config, pkgs, lib, ... }:

let
  userName = config._userName;
  dracula-colorls = pkgs.fetchFromGitHub {
    owner = "dracula";
    repo = "colorls";
    rev = "3f1e3cf325c86e3019a1b7c3776b3a348fe6b530";
    sha256 = "sha256-LyCxBEySPDXAm6PHFA0K8y1EJqz9TkS2AJwT+nv3wyk=";
  };
in
{
  config = {
    environment = {
      systemPackages = with pkgs; [
        colorls
      ];
    };

    home-manager.users.${userName} = {
      xdg.configFile = {
        "colorls/dark_colors.yaml".source = "${dracula-colorls}/dark_colors.yaml";
      };
    };
  };
}
