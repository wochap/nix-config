{ config, pkgs, lib, inputs, ... }:

let cfg = config._custom.programs.zathura;
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
