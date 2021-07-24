{ config, pkgs, lib, ... }:

{
  config = {
    nixpkgs.overlays = [
      # Update discord to latest version
      # https://nixos.wiki/wiki/Discord
      (self: super: {
        discord = super.discord.overrideAttrs (
          _: {
            src = pkgs.fetchurl {
              url = "https://dl.discordapp.net/apps/linux/0.0.14/discord-0.0.14.tar.gz";
              sha256 = "1rq490fdl5pinhxk8lkfcfmfq7apj79jzf3m14yql1rc9gpilrf2";
            };
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
