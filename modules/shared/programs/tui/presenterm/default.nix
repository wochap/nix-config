{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.programs.presenterm;
  inherit (config._custom.globals) themeColorsLight themeColorsDark;
in
{
  options._custom.programs.presenterm.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs; [ presenterm ];

      xdg.configFile = {
        "presenterm/config.yaml" = {
          text = ''
            defaults:
              theme:
                light: catppuccin-${themeColorsLight.flavour}
                dark: catppuccin-${themeColorsDark.flavour}

            ${lib.fileContents ./dotfiles/config.yaml}
          '';
          force = true;
        };
      };
      programs.zsh.initContent = lib.mkOrder 1000 (builtins.readFile ./dotfiles/pt.zsh);
    };
  };
}
