{ config, pkgs, lib, inputs, ... }:

let cfg = config._custom.system.fhs-compat;
in {
  imports = [ inputs.nix-ld.nixosModules.nix-ld ];
  options._custom.system.fhs-compat.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      inputs.nix-alien.packages.${pkgs.system}.nix-alien
      appimage-run
      # NOTE: you can also run non nix pkgs apps with `steam-run`
    ];

    # populates contents of /bin and /usr/bin/
    services.envfs.enable = lib.mkDefault true;

    # more info: https://github.com/mcdonc/.nixconfig/blob/master/videos/pydev/script.rst
    # run unpatched dynamic binaries on NixOS
    programs.nix-ld = {
      enable = true;
      dev.enable = false;
      libraries = with pkgs; [
        # nix-ld adds the following libs by default
        zlib
        zstd
        stdenv.cc.cc
        curl
        openssl
        attr
        libssh
        bzip2
        libxml2
        acl
        libsodium
        util-linux
        xz
        systemd

        # custom libs
        stdenv.cc.cc.lib
        fontconfig
        freetype
      ];
    };
  };
}
