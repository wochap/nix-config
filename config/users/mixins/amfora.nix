{ config, pkgs, lib, inputs, ... }:

let userName = config._userName;
in {
  config = {
    environment.systemPackages = with pkgs; [ amfora ];

    home-manager.users.${userName} = {
      xdg.configFile."amfora/config.toml".text = ''
        ${builtins.readFile "${inputs.dracula-amfora}/Dracula.toml"}
      '';
    };
  };
}
