{ config, pkgs, lib, inputs, ... }:

let
  isWayland = config._displayServer == "wayland";
in
{
  config = {
    nixpkgs.overlays = [
      # inputs.rust-overlay.overlay

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
    ] ++ (if (isWayland) then [
      # inputs.nixpkgs-wayland.overlay-egl
      # inputs.nixpkgs-wayland.overlay

      # {
      #   xwayland = prev.xwayland.overrideAttrs (old: rec {
      #     version = "21.1.3";
      #     src = prev.fetchFromGitLab {
      #       domain = "gitlab.freedesktop.org";
      #       owner = "xorg";
      #       repo = "xserver";
      #       rev = "21e3dc3b5a576d38b549716bda0a6b34612e1f1f";
      #       sha256 = "sha256-i2jQY1I9JupbzqSn1VA5JDPi01nVA6m8FwVQ3ezIbnQ=";
      #     };
      #   });
      # }
    ] else []);
  };
}
