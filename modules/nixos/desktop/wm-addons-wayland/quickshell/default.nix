{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.desktop.quickshell;
  inherit (config._custom.globals) configDirectory;
  quickshell-final = inputs.quickshell.packages.${pkgs.system}.default;
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
      # wallust # pywall like
      # matugen # color generator
    ];

    fonts.packages = with pkgs; [ nixpkgs-unstable.material-symbols ];

    _custom.hm = {
      xdg.configFile = {
        "quickshell".source =
          lib._custom.relativeSymlink configDirectory ./dotfiles;
      };
    };
  };
}
