{ config, pkgs, lib, ... }:

# NOTE: run `sensors-detect`, and load recommended kernel modules
{
  config = {
    environment.systemPackages = with pkgs; [
      # gui
      psensor

      # cli
      lm_sensors
    ];

  };
}
