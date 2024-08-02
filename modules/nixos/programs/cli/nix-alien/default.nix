{ config, pkgs, lib, inputs, ... }:

let cfg = config._custom.programs.nix-alien;
in {
  imports = [ inputs.nix-ld.nixosModules.nix-ld ];
  options._custom.programs.nix-alien.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [ inputs.nix-alien.overlays.default ];

    environment.systemPackages = with pkgs; [ nix-alien ];

    # programs.nix-ld.enable = true;
  };
}
