{ config, pkgs, lib, inputs, ... }:

let
  isWayland = config._displayServer == "wayland";
  userName = config._userName;
in
{
  config = {
    home-manager.users.${userName} = {
      nixpkgs.overlays = [
        inputs.neovim-nightly-overlay.overlay
      ];
    };

    nixpkgs.overlays = [
      # inputs.rust-overlay.overlay

      # inputs.nixpkgs-s2k.overlay

      inputs.neovim-nightly-overlay.overlay

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

        wmutils-core = super.wmutils-core.overrideAttrs (
          _: {
            src = pkgs.fetchFromGitHub {
              owner = "wmutils";
              repo = "core";
              rev = "d989db82b83cf457a3fb9bcd87637cf29770f9a4";
              sha256 = "sha256-ha6YCXk6/p21DAin2zwuOuqXCDjs2Bi5IHFRiVaIE3E=";
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
            sha256 = "sha256-lTwH2ChbU9NRYkHHhzE6vEd6ww/gw78tf5WvaC0iEyY=";
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

        robo3t = (prev.runCommandNoCC "robo3t"
          { buildInputs = with pkgs; [ makeWrapper ]; }
          ''
            makeWrapper ${prev.robo3t}/bin/robo3t $out/bin/robo3t \
              --set "QT_QPA_PLATFORM" "xcb"

            ln -sf ${prev.robo3t}/share $out/share
          ''
        );
      })

      # inputs.nixpkgs-wayland.overlay-egl
      inputs.nixpkgs-wayland.overlay
    ] else []);
  };
}
