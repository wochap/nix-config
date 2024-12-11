{ config, pkgs, lib, inputs, ... }:

let cfg = config._custom.system.fhs-compat;
in {
  imports = [ inputs.nix-ld.nixosModules.nix-ld ];
  options._custom.system.fhs-compat.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [ inputs.nix-alien.overlays.default ];

    environment.systemPackages = with pkgs; [ nix-alien ];

    # populates contents of /bin and /usr/bin/
    services.envfs.enable = lib.mkDefault true;

    # run unpatched dynamic binaries on NixOS
    programs.nix-ld = {
      enable = true;
      dev.enable = false;
      libraries = with pkgs; [ fontconfig freetype stdenv.cc.cc util-linux ];
    };
  };
}
