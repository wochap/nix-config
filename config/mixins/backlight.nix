{ config, pkgs, lib, inputs, ... }:

{
  config = {
    # Update display brightness
    environment.systemPackages = with pkgs; [ brightnessctl ];
    programs.light.enable = true;
  };
}

