{ config, pkgs, lib, ... }:

let cfg = config._custom.services.steam;
in {
  options._custom.services.steam.enable = lib.mkEnableOption { };

  # inspiration: https://www.reddit.com/r/NixOS/comments/15dokde/problems_with_steam_and_gamescope_in_hyprland/
  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        steam = prev.steam.override {
          extraPkgs = pkgs:
            with pkgs; [
              openssl
              gamescope
              mangohud

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

    environment.systemPackages = with pkgs; [
      gamescope
      goverlay
      mangohud
      protonup-qt
    ];
    environment.sessionVariables = {
      STEAM_EXTRA_COMPAT_TOOLS_PATHS =
        [ "$HOME/.local/share/Steam/compatibilitytools.d" ];
    };

    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      gamescopeSession.enable = true;
      # extraCompatPackages = with pkgs;
      #   [ inputs.nix-gaming.packages.${system}.proton-ge ];
    };

    hardware.opengl = {
      extraPackages = with pkgs; [ mangohud ];
      extraPackages32 = with pkgs; [ mangohud ];
    };
  };
}
