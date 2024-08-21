{ config, pkgs, lib, ... }:

let cfg = config._custom.programs.ptsh;
in {
  options._custom.programs.ptsh.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
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
          ppwd = "ptpwd";
          pmkdir = "ptmkdir";
          touch = "pttouch";
          rm = "ptrm";
          # cp = "ptcp";
        };
      };
    };
  };
}
