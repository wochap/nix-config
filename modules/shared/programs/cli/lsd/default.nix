{ config, lib, inputs, ... }:

let
  cfg = config._custom.programs.lsd;
  themeSettings = { };
in {
  options._custom.programs.lsd.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      xdg.configFile = {
        "lsd/colors.yaml".source = "${inputs.dracula-lsd}/dracula.yaml";
        "lsd/icons.yaml".text = ''
          name:
            mail: 
            Mail: 
        '';
      };

      programs.lsd = {
        # TODO: use package option instead of overlay
        enable = true;
        # adds ls ll la lt ll
        enableBashIntegration = true;
        enableZshIntegration = config._custom.programs.zsh.enable;
        settings = lib.recursiveUpdate themeSettings {
          color.theme = "custom";
          sorting.dir-grouping = "first";
          symlink-arrow = "->";
          layout = "grid";
          hyperlink = "auto";
          blocks = [ "permission" "user" "group" "size" "date" "git" "name" ];
          date = "+%a %d %b %H:%M %Y";
        };
      };
    };
  };
}
