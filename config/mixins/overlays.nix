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
        # HACK:
        # https://forums.developer.nvidia.com/t/nvidia-495-does-not-advertise-ar24-xr24-as-shm-formats-as-required-by-wayland-wlroots/194651
        wlroots = prev.wlroots.overrideAttrs(old: {
          postPatch = ''
            sed -i 's/assert(argb8888 &&/assert(true || argb8888 ||/g' 'render/wlr_renderer.c'
          '';
        });

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

      # wayland on nvidia works fine without more overlays
      inputs.nixpkgs-wayland.overlay-egl
      # inputs.nixpkgs-wayland.overlay
    ] else []);
  };
}
