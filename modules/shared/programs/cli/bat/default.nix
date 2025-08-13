{ config, lib, inputs, ... }:

let
  cfg = config._custom.programs.bat;
  inherit (config._custom.globals) themeColorsLight themeColorsDark;
in {
  options._custom.programs.bat.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home = {
        shellAliases = {
          cat = "bat --plain";
          bathelp = "bat --plain --language=help";
        };
        sessionVariables = {
          # Use bat in man pager
          # source: https://github.com/sharkdp/bat?tab=readme-ov-file#man
          MANPAGER = "sh -c 'col -bx | bat -l man -p'";
          MANROFFOPT = "-c";
        };
      };

      programs.bat = {
        enable = true;
        config = {
          theme = "auto";
          theme-light = "Catppuccin ${lib._custom.capitalize themeColorsLight.flavour}";
          theme-dark = "Catppuccin ${lib._custom.capitalize themeColorsDark.flavour}";
        };
        themes = {
          "Catppuccin Latte" = {
            src = "${inputs.catppuccin-bat}/themes";
            file = "Catppuccin Latte.tmTheme";
          };
          "Catppuccin Frappe" = {
            src = "${inputs.catppuccin-bat}/themes";
            file = "Catppuccin Frappe.tmTheme";
          };
          "Catppuccin Macchiato" = {
            src = "${inputs.catppuccin-bat}/themes";
            file = "Catppuccin Macchiato.tmTheme";
          };
          "Catppuccin Mocha" = {
            src = "${inputs.catppuccin-bat}/themes";
            file = "Catppuccin Mocha.tmTheme";
          };
        };
      };
    };
  };
}
