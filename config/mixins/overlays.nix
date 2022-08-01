{ config, pkgs, lib, inputs, ... }:

let
  isWayland = config._displayServer == "wayland";
  isDarwin = config._displayServer == "darwin";
  userName = config._userName;
  localPkgs = import ../packages { inherit pkgs lib; };
in {
  config = {
    home-manager.users.${userName} = {
      nixpkgs.overlays = [ inputs.neovim-nightly-overlay.overlay ];
    };

    nixpkgs.overlays = [
      inputs.neovim-nightly-overlay.overlay

      (final: prev: {

        # Custom channels
        unstable = import inputs.unstable {
          system = prev.system;
          config = config.nixpkgs.config;
        };
        prevstable = import inputs.prevstable {
          system = prev.system;
          config = config.nixpkgs.config;
        };

        wmutils-core = prev.wmutils-core.overrideAttrs (_: {
          src = pkgs.fetchFromGitHub {
            owner = "wmutils";
            repo = "core";
            rev = "d989db82b83cf457a3fb9bcd87637cf29770f9a4";
            sha256 = "sha256-ha6YCXk6/p21DAin2zwuOuqXCDjs2Bi5IHFRiVaIE3E=";
          };
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

      })
    ] ++ (if (isWayland) then
      [
        (final: prev: {

          rofi = prev.rofi.overrideAttrs (old: rec {
            src = prev.fetchurl {
              url =
                "https://github.com/lbonn/rofi/archive/6801bd85bbfa59143b8ec443a05b22ef977b4349.tar.gz";
              sha256 = "sha256-X9E40nJzCIUTPaJNujyayuZH/Hm6/+7akrO0bRovycs=";
            };
          });

          robo3t = (prev.runCommandNoCC "robo3t" {
            buildInputs = with pkgs; [ makeWrapper ];
          } ''
            makeWrapper ${prev.robo3t}/bin/robo3t $out/bin/robo3t \
              --set "QT_QPA_PLATFORM" "xcb"

            ln -sf ${prev.robo3t}/share $out/share
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
