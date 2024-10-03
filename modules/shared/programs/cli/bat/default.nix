{ config, lib, inputs, ... }:

let
  cfg = config._custom.programs.bat;
  inherit (config._custom.globals) themeColors;
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
        config = { theme = "Catppuccin-${themeColors.flavor}"; };
        themes = {
          Catppuccin-latte = {
            src = "${inputs.catppuccin-bat}/themes";
            file = "Catppuccin Latte.tmTheme";
          };
          Catppuccin-frappe = {
            src = "${inputs.catppuccin-bat}/themes";
            file = "Catppuccin Frappe.tmTheme";
          };
          Catppuccin-macchiato = {
            src = "${inputs.catppuccin-bat}/themes";
            file = "Catppuccin Macchiato.tmTheme";
          };
          Catppuccin-mocha = {
            src = "${inputs.catppuccin-bat}/themes";
            file = "Catppuccin Mocha.tmTheme";
          };
        };
      };
    };
  };
}
