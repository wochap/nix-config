{ config, pkgs, lib, inputs, ... }:

let
  isDarwin = config._displayServer == "darwin";
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
        prevstable-kitty = import inputs.prevstable-kitty {
          inherit (prev) system;
          inherit (config.nixpkgs) config;
          overlays = overlaysWithoutCustomChannels;
        };
      })
    ] ++ (lib.optionals isDarwin [
      inputs.nur.overlay
      inputs.spacebar.overlay.x86_64-darwin

      (final: prev: {
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
