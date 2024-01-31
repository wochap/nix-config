{ config, pkgs, lib, ... }:

let cfg = config._custom.services.steam;
in {
  options._custom.services.steam = { enable = lib.mkEnableOption { }; };

  # inspiration: https://www.reddit.com/r/NixOS/comments/15dokde/problems_with_steam_and_gamescope_in_hyprland/
  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        steam = prev.steam.override {
          extraPkgs = pkgs:
            with pkgs; [
              gamescope
              keyutils
              libkrb5
              libpng
              libpulseaudio
              libvorbis
              mangohud
              stdenv.cc.cc.lib
              xorg.libXScrnSaver
              xorg.libXcursor
              xorg.libXi
              xorg.libXinerama
            ];
        };
      })
    ];

    environment.systemPackages = with pkgs; [ gamescope mangohud ];

    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      gamescopeSession.enable = true;
    };

    hardware.opengl = {
      extraPackages = with pkgs; [ mangohud ];
      extraPackages32 = with pkgs; [ mangohud ];
    };

    _custom.hm = {
      programs.mangohud = {
        enable = true;
        settings = {
          full = true;
          cpu_load_change = true;
        };
      };
    };
  };
}
