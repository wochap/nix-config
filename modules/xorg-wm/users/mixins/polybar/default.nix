{ config, pkgs, lib, ... }:

let
  cfg = config._custom.xorgWm;
  theme = config._theme;
  localPkgs = import ../../../packages { pkgs = pkgs; lib = lib; };
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  mkOutOfStoreSymlink = hmConfig.lib.file.mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory = "${configDirectory}/config/users/mixins/polybar";
  customPolybar = pkgs.polybar.override {
    alsaSupport = true;
    mpdSupport = true;
    pulseSupport = true;
  };
  toPolybarIni = lib.generators.toINI {
    mkKeyValue = lib.generators.mkKeyValueDefault {
      mkValueString = v:
        if lib.isString v then
          ''"${v}"''
        else
          lib.generators.mkValueStringDefault { } v;
    } "=";
  };
in {
  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        customPolybar
      ];
      etc = {
        "scripts/polybar-toggle.sh" = {
          source = ./scripts/polybar-toggle.sh;
          mode = "0755";
        };
        "scripts/polybar-start.sh" = {
          source = ./scripts/polybar-start.sh;
          mode = "0755";
        };
      };
    };

    home-manager.users.${userName} = {
      xdg.configFile = {
        "polybar/colors.ini".text = toPolybarIni { themeColors = theme; };
        "polybar/config.ini".source = mkOutOfStoreSymlink "${currentDirectory}/dotfiles/main.ini";
        "polybar/blocks.ini".source = mkOutOfStoreSymlink "${currentDirectory}/dotfiles/blocks.ini";

        "polybar/scripts/bspwm_monocle_windows.sh" = {
          source = ./dotfiles/scripts/bspwm_monocle_windows.sh;
          executable = true;
        };
        "polybar/scripts/bspwm_hidden_windows.sh" = {
          source = ./dotfiles/scripts/bspwm_hidden_windows.sh;
          executable = true;
        };
        "polybar/scripts/rextie_usd.js" = {
          source = ./dotfiles/scripts/rextie_usd.js;
          executable = true;
        };
        "polybar/scripts/btc_usd.js" = {
          source = ./dotfiles/scripts/btc_usd.js;
          executable = true;
        };
        "polybar/scripts/doge_usd.js" = {
          source = ./dotfiles/scripts/doge_usd.js;
          executable = true;
        };
      };
    };
  };
}
