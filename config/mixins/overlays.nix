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
      (final: prev: {
        egl-wayland = prev.egl-wayland.overrideAttrs (old: rec {
          pname = "egl-wayland";
          version = "1.1.9.999";
          name = "${pname}-${version}";
          src = final.fetchFromGitHub {
            owner = "Nvidia";
            repo = "egl-wayland";
            rev = "daab8546eca8428543a4d958a2c53fc747f70672";
            sha256 = "sha256-IrLeqBW74mzo2OOd5GzUPDcqaxrsoJABwYyuKTGtPsw=";
          };
          buildInputs = old.buildInputs ++ [ final.wayland-protocols ];
        });


        xwayland = prev.xwayland.overrideAttrs (old: rec{
          version = "21.1.2.901";
          src = prev.fetchFromGitLab {
            domain = "gitlab.freedesktop.org";
            owner = "xorg";
            repo = "xserver";
            rev = "xwayland-21.1.2.901";
            sha256 = "sha256-TOsxN+TVMICYhqkypqrFgzI/ln87ALb9LijPgHmlcos=";
          };
        });
      })

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
