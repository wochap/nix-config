{ config, pkgs, lib, ... }:

{
  config = {
    nixpkgs.overlays = [
      # Update discord to latest version
      # https://nixos.wiki/wiki/Discord
      (self: super: {
        discord = super.discord.overrideAttrs (
          _: {
            src = builtins.fetchTarball "https://discord.com/api/download?platform=linux&format=tar.gz";
          }
        );
      })

      # Update polybar to latest version
      (self: super: {
        polybar = super.polybar.overrideAttrs (
          _: {
            src = pkgs.fetchFromGitHub {
              owner = "polybar";
              repo = "polybar";
              rev = "5f3462240cddfca15a52092633f77d2d4fa55278";
              sha256 = "1vmq9bs979bmkdm7hxsq0m0ql26ab70gwl2jlxxicdb6p9k921hh";
              fetchSubmodules = true;
            };
          }
        );
      })
    ];
  };
}
