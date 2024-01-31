{ config, pkgs, lib, ... }:

let
  cfg = config._custom.cli.ptsh;
  userName = config._userName;
in {
  options._custom.cli.ptsh = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    home-manager.users.${userName} = {
      home = {
        packages = with pkgs; [ _custom.ptsh ];

        file = {
          ".local/share/ptSh/logo.txt".source =
            "${pkgs._custom.ptsh}/share/ptSh/logo.txt";
          ".local/share/ptSh/LICENSE".source =
            "${pkgs._custom.ptsh}/share/ptSh/LICENSE";
          ".local/share/ptSh/version.txt".text =
            "${pkgs._custom.ptsh}/share/ptSh/version.txt";
          ".local/share/ptSh/config".source =
            "${pkgs._custom.ptsh}/share/ptSh/config";
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
