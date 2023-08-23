{ config, pkgs, lib, inputs, ... }:

let userName = config._userName;
in {
  config = {
    home-manager.users.${userName} = {
      home.sessionVariables = {
        NIXOS_CONFIG = "/home/${userName}/nix-config/devices/desktop.nix";
      };
    };
  };
}
