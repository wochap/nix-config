{ config, pkgs, lib, inputs, ... }:

let
  isWayland = config._displayServer == "wayland";
  isDarwin = config._displayServer == "darwin";
  userName = config._userName;
  localPkgs = import ../packages { inherit pkgs lib; };
  overlaysWithoutCustomChannels = lib.tail config.nixpkgs.overlays;
in {
  config = {
    # home-manager.users.${userName} = {
    #   nixpkgs.overlays = [ inputs.neovim-nightly-overlay.overlay ];
    # };

    nixpkgs.overlays = [
      # inputs.neovim-nightly-overlay.overlay

      (final: prev: {
        # Custom channels
        unstable = import inputs.unstable {
          inherit (prev) system;
          inherit (config.nixpkgs) config;
          overlays = overlaysWithoutCustomChannels;
        };
        prevstable-neovim = import inputs.prevstable-neovim {
          inherit (prev) system;
          inherit (config.nixpkgs) config;
          overlays = overlaysWithoutCustomChannels;
        };
        prevstable-mongodb = import inputs.prevstable-mongodb {
          inherit (prev) system;
          inherit (config.nixpkgs) config;
          overlays = overlaysWithoutCustomChannels;
        };
        prevstable-python = import inputs.prevstable-python {
          inherit (prev) system;
          inherit (config.nixpkgs) config;
          overlays = overlaysWithoutCustomChannels;
        };
      })

      (final: prev: {
        wmutils-core = prev.wmutils-core.overrideAttrs (_: {
          src = pkgs.fetchFromGitHub {
            owner = "wmutils";
            repo = "core";
            rev = "d989db82b83cf457a3fb9bcd87637cf29770f9a4";
            sha256 = "sha256-ha6YCXk6/p21DAin2zwuOuqXCDjs2Bi5IHFRiVaIE3E=";
          };
        });

        wob = prev.wob.overrideAttrs (_: {
          src = pkgs.fetchFromGitHub {
            owner = "francma";
            repo = "wob";
            rev = "75a65e6c33e916a5453d705ed5b3b21335587631";
            sha256 = "sha256-N6+UUCRerzswbU5XpoNeG6Qu//QSyXD4mTIXwCPXMsU=";
          };

          buildInputs = with pkgs; [ inih wayland wayland-protocols pixman cmocka ]
            ++ lib.optional stdenv.isLinux pkgs.libseccomp;
        });

        dracula-theme = prev.dracula-theme.overrideAttrs
          (_: { src = inputs.dracula-gtk-theme; });

        orchis = prev.orchis.overrideAttrs (_: {
          src = prev.fetchFromGitHub {
            repo = "Orchis-theme";
            owner = "vinceliuice";
            rev = "a0190354f93b4acbdb8636aef83d35a9dea8e0e8";
            sha256 = "sha256-T8qaHeMMJ0RgTJavmmxKggnKatKc7Gs7bDLYxT6b1Bg=";
          };
        });

        tela-icon-theme = prev.tela-icon-theme.overrideAttrs (_: {
          src = prev.fetchFromGitHub {
            owner = "vinceliuice";
            repo = "Tela-icon-theme";
            rev = "184959a91ed9726d7cbb3d55c627be09d302096f";
            sha256 = "sha256-mvkgHBdZm6vF+/DS3CRLl1m14U0Lj4Xtz4J/vpJUTQM=";
          };
        });

        i3lock-color = prev.i3lock-color.overrideAttrs (_: {
          src = prev.fetchFromGitHub {
            owner = "PandorasFox";
            repo = "i3lock-color";
            rev = "995f58dc7323d53095f1687ae157bfade1d00542";
            sha256 = "sha256-2ojaIRtQpGzgPUwvhX1KsStMdCHuYSaZt3ndP1EBHmE=";
          };
        });

        lazygit = prev.lazygit.overrideAttrs (_: {
          src = prev.fetchFromGitHub {
            owner = "jesseduffield";
            repo = "lazygit";
            rev = "v0.31.4";
            sha256 = "sha256-yze4UaSEbyHwHSyj0mM7uCzaDED+p4O3HVVlHJi/FKU=";
          };
        });

        # neovide = prev.neovide.overrideAttrs (drv: rec {
        #   cargoDeps = drv.cargoDeps.overrideAttrs (_: {
        #     inherit src;
        #     outputHash = "sha256-1BkEx2emvGdA8agoBgeEyoz1Z9G3SB0M8ORTNat+PqU=";
        #   });
        #   src = prev.fetchFromGitHub {
        #     owner = "neovide";
        #     repo = "neovide";
        #     rev = "2766fe7f84d4d1825d7399378fdd3b0e1ce7f4a6";
        #     sha256 = "sha256-1WoVeobqOvT72Ml+gtVS1URYZFifMdKXLwHOMq1HUww=";
        #   };
        # });

      })
    ] ++ (if (isWayland) then
      [
        (final: prev: {

          waybar = prev.waybar.overrideAttrs (oldAttrs: {
            mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
          });

          mako = prev.mako.overrideAttrs (old: rec {
            version = "1.7.1";
            src = pkgs.fetchFromGitHub {
              owner = "emersion";
              repo = "mako";
              rev = "v1.7.1";
              sha256 = "sha256-/+XYf8FiH4lk7f7/pMt43hm13mRK+UqvaNOpf1TI6m4=";
            };
          });

          robo3t = (prev.runCommandNoCC "robo3t" {
            buildInputs = with pkgs; [ makeWrapper ];
          } ''
            makeWrapper ${prev.robo3t}/bin/robo3t $out/bin/robo3t \
              --set "QT_QPA_PLATFORM" "xcb"

            ln -sf ${prev.robo3t}/share $out/share
          '');

          insomnia = (prev.runCommandNoCC "insomnia" {
            buildInputs = with pkgs; [ makeWrapper ];
          } ''
            makeWrapper ${prev.insomnia}/bin/insomnia $out/bin/insomnia \
              --add-flags "--enable-features=UseOzonePlatform" \
              --add-flags "--ozone-platform=wayland"

            ln -sf ${prev.insomnia}/share $out/share
          '');

          microsoft-edge = (prev.runCommandNoCC "microsoft-edge" {
            buildInputs = with pkgs; [ makeWrapper ];
          } ''
            makeWrapper ${prev.microsoft-edge}/bin/microsoft-edge $out/bin/microsoft-edge \
              --add-flags "--enable-features=WebRTCPipeWireCapturer" \
              --add-flags "--enable-features=UseOzonePlatform" \
              --add-flags "--ozone-platform=wayland"

            ln -sf ${prev.microsoft-edge}/share $out/share
          '');

        })

        # inputs.nixpkgs-wayland.overlay-egl
        # inputs.nixpkgs-wayland.overlay
      ]
    else
      [ ]) ++ (if (isDarwin) then [
        inputs.nur.overlay
        inputs.spacebar.overlay.x86_64-darwin

        (final: prev: {
          sf-mono-liga-bin = localPkgs.sf-mono-liga-bin;

          # yabai is broken on macOS 12, so lets make a smol overlay to use the master version
          yabai = let
            version = "4.0.0";
            buildSymlinks = prev.runCommand "build-symlinks" { } ''
              mkdir -p $out/bin
              ln -s /usr/bin/xcrun /usr/bin/xcodebuild /usr/bin/tiffutil /usr/bin/qlmanage $out/bin
            '';
          in prev.yabai.overrideAttrs (old: {
            inherit version;
            src = inputs.yabai-src;

            buildInputs = with prev.darwin.apple_sdk.frameworks; [
              Carbon
              Cocoa
              ScriptingBridge
              prev.xxd
              SkyLight
            ];

            nativeBuildInputs = [ buildSymlinks ];
          });
        })
      ] else
        [ ]);
  };
}
