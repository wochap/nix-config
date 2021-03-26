{ config, pkgs, lib, ... }:

{
  config = {
    # Update discord to latest version
    # https://nixos.wiki/wiki/Discord
    nixpkgs.overlays = [
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
    ];
  };
}
