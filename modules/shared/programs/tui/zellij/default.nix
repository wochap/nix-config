{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.programs.zellij;
  inherit (config._custom.globals)
    themeColorsLight
    themeColorsDark
    preferDark
    ;
in
{
  options._custom.programs.zellij = {
    enable = lib.mkEnableOption { };
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.zellij;
    };
  };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs; [ cfg.package ];

      xdg.configFile = {
        "zellij/config.kdl".text = ''
          theme "${if preferDark then themeColorsDark.flavour else themeColorsLight.flavour}"
          theme_dark "${themeColorsDark.flavour}"
          theme_light "${themeColorsLight.flavour}"

          ${builtins.readFile ./dotfiles/config.kdl}
        '';
      };
    };
  };
}
