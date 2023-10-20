{ config, pkgs, lib, inputs, ... }:

let
  isDarwin = config._displayServer == "darwin";
  localPkgs = import ../packages { inherit pkgs lib; };
  overlaysWithoutCustomChannels = lib.tail config.nixpkgs.overlays;
in {
  config = {

    nixpkgs.overlays = [
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
        prevstable-nodejs = import inputs.prevstable-nodejs {
          inherit (prev) system;
          inherit (config.nixpkgs) config;
          overlays = overlaysWithoutCustomChannels;
        };
        prevstable-chrome = import inputs.prevstable-chrome {
          inherit (prev) system;
          inherit (config.nixpkgs) config;
          overlays = overlaysWithoutCustomChannels;
        };
        prevstable-kernel-pkgs = import inputs.prevstable-kernel-pkgs {
          inherit (prev) system;
          inherit (config.nixpkgs) config;
          overlays = overlaysWithoutCustomChannels;
        };
      })

      (final: prev: {
        heimdall = prev.heimdall.overrideAttrs (_: {
          src = prev.fetchFromSourcehut {
            owner = "~grimler";
            repo = "Heimdall";
            rev = "02b577ec774f2ce66bcb4cf96cf15d8d3d4c7720";
            sha256 = "sha256-tcAE83CEHXCvHSn/S9pWu6pUiqGmukMifEadqPDTkQ0=";
          };
        });

        _custom = localPkgs;
      })
    ] ++ (lib.optionals isDarwin [
      inputs.nur.overlay
      inputs.spacebar.overlay.x86_64-darwin

      (final: prev: {
        inherit (localPkgs) sf-mono-liga-bin;

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
    ]);
  };
}
