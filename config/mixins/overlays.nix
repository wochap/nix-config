{ config, pkgs, lib, inputs, ... }:

let
  isWayland = config._displayServer == "wayland";
in
{
  config = {
    nixpkgs.overlays = [
      # inputs.rust-overlay.overlay

      (self: super: {
        # Update polybar to latest version
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

        orchis = super.orchis.overrideAttrs (
          _: {
            src = super.fetchFromGitHub {
              repo = "Orchis-theme";
              owner = "vinceliuice";
              rev = "a0190354f93b4acbdb8636aef83d35a9dea8e0e8";
              sha256 = "sha256-T8qaHeMMJ0RgTJavmmxKggnKatKc7Gs7bDLYxT6b1Bg=";
            };
          }
        );

        tela-icon-theme = super.tela-icon-theme.overrideAttrs (
          _: {
            src = super.fetchFromGitHub {
              owner = "vinceliuice";
              repo = "Tela-icon-theme";
              rev = "184959a91ed9726d7cbb3d55c627be09d302096f";
              sha256 = "sha256-mvkgHBdZm6vF+/DS3CRLl1m14U0Lj4Xtz4J/vpJUTQM=";
            };
          }
        );

        i3lock-color = super.i3lock-color.overrideAttrs (
          _: {
            src = super.fetchFromGitHub {
              owner = "PandorasFox";
              repo = "i3lock-color";
              rev = "995f58dc7323d53095f1687ae157bfade1d00542";
              sha256 = "sha256-2ojaIRtQpGzgPUwvhX1KsStMdCHuYSaZt3ndP1EBHmE=";
            };
          }
        );
      })
    ] ++ (if (isWayland) then [
      (final: prev: {
        # HACK:
        # https://forums.developer.nvidia.com/t/nvidia-495-does-not-advertise-ar24-xr24-as-shm-formats-as-required-by-wayland-wlroots/194651
        # wlroots = prev.wlroots.overrideAttrs(old: {
        #   postPatch = ''
        #     sed -i 's/assert(argb8888 &&/assert(true || argb8888 ||/g' 'render/wlr_renderer.c'
        #   '';
        # });

        # egl-wayland = prev.egl-wayland.overrideAttrs (old: rec {
        #   pname = "egl-wayland";
        #   version = "1.1.9.999";
        #   name = "${pname}-${version}";
        #   src = final.fetchFromGitHub {
        #     owner = "Nvidia";
        #     repo = "egl-wayland";
        #     rev = "daab8546eca8428543a4d958a2c53fc747f70672";
        #     sha256 = "sha256-IrLeqBW74mzo2OOd5GzUPDcqaxrsoJABwYyuKTGtPsw=";
        #   };
        #   buildInputs = old.buildInputs ++ [ final.wayland-protocols ];
        # });

        # xwayland = prev.xwayland.overrideAttrs (old: rec {
        #   version = "21.1.2.901";
        #   src = prev.fetchFromGitLab {
        #     domain = "gitlab.freedesktop.org";
        #     owner = "xorg";
        #     repo = "xserver";
        #     rev = "xwayland-21.1.2.901";
        #     sha256 = "sha256-TOsxN+TVMICYhqkypqrFgzI/ln87ALb9LijPgHmlcos=";
        #   };
        # });

        rofi = prev.rofi.overrideAttrs (old: rec {
          src = prev.fetchurl {
            url = "https://github.com/lbonn/rofi/archive/70efa84f9bdf46593ee9d1a11acfe0a6e1c899a7.tar.gz";
            sha256 = "04glljqbf9ckkc6x6fv4x1gqmy468n1agya0kd8rxdvz24wzf7c5";
          };
        });

        slack = (prev.runCommandNoCC "slack"
          { buildInputs = with pkgs; [ makeWrapper ]; }
          ''
            makeWrapper ${prev.slack}/bin/slack $out/bin/slack \
              --add-flags "--enable-features=UseOzonePlatform" \
              --add-flags "--ozone-platform=wayland"

            ln -sf ${prev.slack}/share $out/share
          ''
        );

        postman = (prev.runCommandNoCC "postman"
          { buildInputs = with pkgs; [ makeWrapper ]; }
          ''
            makeWrapper ${prev.postman}/bin/postman $out/bin/postman \
              --add-flags "--enable-features=UseOzonePlatform" \
              --add-flags "--ozone-platform=wayland"

            ln -sf ${prev.postman}/share $out/share
          ''
        );
      })

      # wayland on nvidia works fine without more overlays
      inputs.nixpkgs-wayland.overlay-egl
      # sway doesnt launch with overlay ⬇
      # inputs.nixpkgs-wayland.overlay
    ] else []);
  };
}
