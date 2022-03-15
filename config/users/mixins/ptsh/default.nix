{ config, pkgs, lib, inputs, ... }:

let
  userName = config._userName;
  localPkgs = import ../../../packages { inherit pkgs lib; };
  ptsh-repo = inputs.ptsh;
in {
  config = {
    home-manager.users.${userName} = {
      home = {
        packages = [ localPkgs.ptsh ];

        file = {
          ".local/share/ptSh/logo.txt".source = "${ptsh-repo}/src/logo.txt";
          ".local/share/ptSh/LICENSE".source = "${ptsh-repo}/LICENSE";
          ".local/share/ptSh/version.txt".text =
            "Version: cloned from v0.2-alpha";
          ".local/share/ptSh/config".source = "${ptsh-repo}/src/config";
          ".config/ptSh/config".source = ./dotfiles/config;
        };

        shellAliases = {
          # Setup ptSh
          pwdd = "ptpwd";
          mkdir = "ptmkdir";
          touch = "pttouch";
          rm = "ptrm";
          # cp = "ptcp";
        };
      };
    };
  };
}
