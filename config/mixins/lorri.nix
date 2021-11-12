{ config, pkgs, lib, ... }:

{
  config = {
    environment.systemPackages = with pkgs; [
      direnv # auto run nix-shell
    ];

    services.lorri.enable = true;
  };
}
