{ config, pkgs, lib, inputs, ... }:

let userName = config._userName;
in {
  config = {
    home-manager.users.${userName} = {
      xdg.configFile."lsd/themes/dracula.yaml".source =
        "${inputs.dracula-lsd}/dracula.yaml";

      programs.lsd = {
        enable = true;
        # adds ls ll la lt ll
        enableAliases = true;
        settings = {
          sorting = { dir-grouping = "first"; };
          symlink-arrow = "->";
        } // pkgs._custom.fromYAML "${inputs.dracula-lsd}/config.yaml";
      };
    };
  };
}
