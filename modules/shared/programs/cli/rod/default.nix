{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.programs.rod;
  tomlFormat = pkgs.formats.toml { };
in {
  options._custom.programs.rod = {
    enable = lib.mkEnableOption { };
    config = lib.mkOption {
      type = tomlFormat.type;
      default = { };
      example = lib.literalExpression ''
        {
          "dark.env" = {
            THEME = "dark";
          };
          "cmds.fzf.light" = {
              pre_args = ["--color=light"];
              pos_args = [];
          };
        }
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    _custom.programs.rod.config = {
      dark.env = { THEME = "dark"; };
      light.env = { THEME = "light"; };
    };

    _custom.hm = {
      home.packages = with pkgs; [ inputs.rod.packages."${system}".default ];

      xdg.configFile."rod/config.toml" = {
        source = tomlFormat.generate "config.toml" cfg.config;
        force = true;
      };

      programs.zsh.initContent =
        lib.mkOrder 1000 (builtins.readFile ./dotfiles/rod.zsh);
    };
  };
}
