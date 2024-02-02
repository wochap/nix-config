{ config, pkgs, lib, inputs, ... }:

let cfg = config._custom.cli.nix-alien;
in {
  options._custom.cli.nix-alien.enable = lib.mkEnableOption { };

  imports = [ inputs.nix-ld.nixosModules.nix-ld ];

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [ inputs.nix-alien.overlays.default ];

    environment.systemPackages = with pkgs; [ nix-alien ];

    programs.nix-ld.enable = true;
  };
}
