{ config, pkgs, lib, inputs, ... }:

let
  userName = config._userName;
in
{
  config = {
    fonts = {
      fonts = with pkgs; [
        emacs-all-the-icons-fonts
      ];
    };

    home-manager.users.${userName} = {
      imports = [
        inputs.nix-doom-emacs.hmModule
      ];

      programs.doom-emacs = {
        enable = true;
        doomPrivateDir = ./dotfiles/doom.d;
      };

      home.file.".emacs.d/init.el".text = ''
        (load "default.el")
      '';
    };
  };
}
