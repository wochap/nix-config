{ config, lib, inputs, ... }:

let overlaysWithoutCustomChannels = lib.tail config.nixpkgs.overlays;
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
    ];
  };
}
