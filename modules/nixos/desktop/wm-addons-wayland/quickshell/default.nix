{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.desktop.quickshell;
  inherit (config._custom.globals)
    themeColorsLight themeColorsDark preferDark configDirectory;
  quickshell-final = inputs.quickshell.packages.${pkgs.system}.default;

  shell-capslock = pkgs.writeScriptBin "shell-capslock"
    (builtins.readFile ./scripts/shell-capslock.sh);
  shell-hypr-ws-special-count =
    pkgs.writeScriptBin "shell-hypr-ws-special-count"
    (builtins.readFile ./scripts/shell-hypr-ws-special-count.sh);
  shell-network = pkgs.writeScriptBin "shell-network"
    (builtins.readFile ./scripts/shell-network.sh);
  shell-bluetooth = pkgs.writeScriptBin "shell-bluetooth"
    (builtins.readFile ./scripts/shell-bluetooth.sh);
  mkThemeQuickshell = themeColors:
    pkgs.writeText "theme.json" (builtins.toJSON themeColors);
  catppuccin-quickshell-light-theme-path = mkThemeQuickshell themeColorsLight;
  catppuccin-quickshell-dark-theme-path = mkThemeQuickshell themeColorsDark;
in {
  options._custom.desktop.quickshell = {
    enable = lib.mkEnableOption { };
    package = lib.mkOption {
      type = lib.types.package;
      default = quickshell-final;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # quickshell deps
      cfg.package
      kdePackages.qt5compat

      # shell deps
      ddcutil # query monitor
      rink # calculator
      wallust # pywall like
      matugen # color generator
    ];

    fonts.packages = with pkgs; [ nixpkgs-unstable.material-symbols ];

    _custom.hm = {
      home.packages = with pkgs; [
        shell-capslock
        shell-hypr-ws-special-count
        shell-network
        shell-bluetooth
      ];

      xdg.configFile = {
        "quickshell/shell".source =
          lib._custom.relativeSymlink configDirectory ./dotfiles/shell;
        "quickshell/theme.json" = {
          source = if preferDark then
            catppuccin-quickshell-dark-theme-path
          else
            catppuccin-quickshell-light-theme-path;
          force = true;
        };
        "quickshell/theme-light.json".source =
          catppuccin-quickshell-light-theme-path;
        "quickshell/theme-dark.json".source =
          catppuccin-quickshell-dark-theme-path;
      };
    };
  };
}
