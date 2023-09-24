{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.nix-alien;
  userName = config._userName;
in {
  options._custom.nix-alien = { enable = lib.mkEnableOption {}; };

  modules = [
        nix-ld.nixosModules.nix-ld
        ];

  config = lib.mkIf cfg.enable {
nixpkgs.overlays = [
              self.inputs.nix-alien.overlays.default
            ];

environment.systemPackages = with pkgs; [
              nix-alien
            ];

programs.nix-ld.enable = true;
  };
}

