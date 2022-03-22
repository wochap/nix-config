{ config, pkgs, lib, inputs, ... }:

let
  isWayland = config._displayServer == "wayland";
  isDarwin = config._displayServer == "darwin";
  userName = config._userName;
in {
  config = {
    home-manager.users.${userName} = {
      nixpkgs.overlays = [ inputs.neovim-nightly-overlay.overlay ];
    };

    nixpkgs.overlays = [
      # inputs.rust-overlay.overlay

      # inputs.nixpkgs-s2k.overlay

      inputs.neovim-nightly-overlay.overlay

      (final: prev: {

        # Custom channels
        unstable = import inputs.unstable {
          system = prev.system;
          config = config.nixpkgs.config;
        };
        electron-stable = import inputs.electron-stable {
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
              url =
                "https://github.com/lbonn/rofi/archive/70efa84f9bdf46593ee9d1a11acfe0a6e1c899a7.tar.gz";
              sha256 = "sha256-lTwH2ChbU9NRYkHHhzE6vEd6ww/gw78tf5WvaC0iEyY=";
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
