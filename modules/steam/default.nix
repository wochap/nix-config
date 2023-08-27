{ config, pkgs, lib, ... }:

let
  cfg = config._custom.steam;
  userName = config._userName;
in {
  options._custom.steam = { enable = lib.mkEnableOption { }; };

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
              stdenv.cc.cc.lib
              xorg.libXScrnSaver
              xorg.libXcursor
              xorg.libXi
              xorg.libXinerama
            ];
        };
      })
    ];

    environment.systemPackages = with pkgs; [ gamescope ];

    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };
  };
}
