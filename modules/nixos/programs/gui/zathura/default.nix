{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.programs.zathura;
  inherit (config._custom.globals) themeColors;
in {
  options._custom.programs.zathura.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home = {
        packages = with pkgs; [ zathura ];
        sessionVariables.READER = "zathura";
      };

      xdg.configFile = {
        "zathura/catppuccin-mocha".source =
          "${inputs.catppuccin-zathura}/src/catppuccin-mocha";
        "zathura/zathurarc".source = pkgs.substituteAll {
          src = ./dotfiles/zathurarc;
          inherit (themeColors) backgroundOverlay;
        };
      };

      xdg.mimeApps = {
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
