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

      tofi-drun --config "$HOME/.config/tofi/one-line"
    '';
  };
in {
  config = lib.mkIf cfg.enable {
    home-manager.users.${userName} = {
      home = { packages = with pkgs; [ unstable.tofi tofi-launcher ]; };

      xdg.configFile = {
        "tofi/multi-line".source =
          mkOutOfStoreSymlink "${currentDirectory}/dotfiles/multi-line";
        "tofi/one-line".source =
          mkOutOfStoreSymlink "${currentDirectory}/dotfiles/one-line";
      };
    };
  };
}
