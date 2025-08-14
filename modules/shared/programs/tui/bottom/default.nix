{ config, lib, inputs, ... }:

let
  cfg = config._custom.programs.bottom;
  inherit (config._custom.globals) themeColorsLight themeColorsDark preferDark;

  # TODO: wait for https://github.com/ClementTsang/bottom/issues/1284
  mkThemeBottom = themeColors: ''
    ${lib.fileContents ./dotfiles/bottom.toml}
    ${lib.fileContents
    "${inputs.catppuccin-bottom}/themes/${themeColors.flavour}.toml"}
  '';
  catppuccin-bottom-light-theme = mkThemeBottom themeColorsLight;
  catppuccin-bottom-dark-theme = mkThemeBottom themeColorsDark;
in {
  options._custom.programs.bottom.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.shellAliases.top = "btm";

      xdg.configFile = {
        "bottom/bottom.toml" = {
          text = if preferDark then
            catppuccin-bottom-dark-theme
          else
            catppuccin-bottom-light-theme;
          force = true;
        };
        "bottom/bottom-light.toml".text = catppuccin-bottom-light-theme;
        "bottom/bottom-dark.toml".text = catppuccin-bottom-dark-theme;
      };

      # useful keymaps
      # % toggle memoryvalues
      # t toggle tree view
      # P toggle viewing the full command
      # tab toggle grouping same apps
      programs.bottom.enable = true;
    };
  };
}
