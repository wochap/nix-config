{ config, lib, pkgs, inputs, ... }:

let
  cfg = config._custom.programs.dircolors;
  inherit (config._custom.globals) themeColorsLight themeColorsDark preferDark;

  dircolorsPath = "~/.dir_colors";
  catppuccin-dircolors-light-theme-path =
    "${inputs.catppuccin-dircolors}/themes/catppuccin-${themeColorsLight.flavour}/.dircolors";
  catppuccin-dircolors-dark-theme-path =
    "${inputs.catppuccin-dircolors}/themes/catppuccin-${themeColorsDark.flavour}/.dircolors";
in {
  options._custom.programs.dircolors = {
    enable = lib.mkEnableOption { };
    package = lib.mkPackageOption pkgs "dircolors" { default = "coreutils"; };
    enableBashIntegration = lib.mkEnableOption { };
    enableZshIntegration = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.file = {
        ".dir_colors" = {
          source = if preferDark then
            catppuccin-dircolors-dark-theme-path
          else
            catppuccin-dircolors-light-theme-path;
          force = true;
        };
        ".dir_colors-light".source = catppuccin-dircolors-light-theme-path;
        ".dir_colors-dark".source = catppuccin-dircolors-dark-theme-path;
      };

      programs.bash.initExtra = lib.mkIf cfg.enableBashIntegration ''
        eval $(${lib.getExe' cfg.package "dircolors"} -b ${dircolorsPath})
      '';

      # Set `LS_COLORS` before Oh My Zsh and `initExtra`.
      programs.zsh.initContent = lib.mkIf cfg.enableZshIntegration
        (lib.mkOrder 550 ''
          eval $(${lib.getExe' cfg.package "dircolors"} -b ${dircolorsPath})
        '');

      programs.dircolors.enable = false;
    };
  };
}

