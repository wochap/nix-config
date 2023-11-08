{ config, lib, pkgs, ... }:

let
  cfg = config._custom.waylandWm;
  inherit (config._custom.globals) themeColors;
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  inherit (hmConfig.lib.file) mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory = "${configDirectory}/modules/wayland-wm/mixins/tofi";

  tofi-launcher = pkgs.writeTextFile {
    name = "tofi-launcher";
    destination = "/bin/tofi-launcher";
    executable = true;
    text = ''
      #!/usr/bin/env bash

      tofi-drun --config "$HOME/.config/tofi/one-line" --drun-launch=false | xargs zsh -c --
    '';
  };
  tofi-powermenu = pkgs.writeTextFile {
    name = "tofi-powermenu";
    destination = "/bin/tofi-powermenu";
    executable = true;
    text = builtins.readFile ./scripts/tofi-powermenu.sh;
  };
  tofi-emoji = pkgs.writeTextFile {
    name = "tofi-emoji";
    destination = "/bin/tofi-emoji";
    executable = true;
    text = builtins.readFile ./scripts/tofi-emoji.sh;
  };
  tofi-calc = pkgs.writeTextFile {
    name = "tofi-calc";
    destination = "/bin/tofi-calc";
    executable = true;
    text = builtins.readFile ./scripts/tofi-calc.sh;
  };
in {
  config = lib.mkIf cfg.enable {
    home-manager.users.${userName} = {
      home = {
        packages = with pkgs; [
          unstable.tofi
          tofi-launcher
          tofi-powermenu
          tofi-emoji
          tofi-calc
        ];
      };

      xdg.configFile = {
        "tofi/multi-line".source =
          mkOutOfStoreSymlink "${currentDirectory}/dotfiles/multi-line";
        "tofi/one-line".source = pkgs.substituteAll {
          src = ./dotfiles/one-line;
          inherit (themeColors) foreground primary background red;
        };
      };
    };
  };
}
