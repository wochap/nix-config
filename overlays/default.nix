{ lib, config, inputs, pkgs, ... }:

let overlaysWithoutCustomChannels = lib.tail config.nixpkgs.overlays;
in {
  config = {
    nixpkgs.overlays = [
      # Custom channels
      (final: prev: {
        unstable = import inputs.unstable {
          inherit (prev) system;
          inherit (config.nixpkgs) config;
          overlays = overlaysWithoutCustomChannels;
        };
        stable = import inputs.stable {
          inherit (prev) system;
          inherit (config.nixpkgs) config;
          overlays = overlaysWithoutCustomChannels;
        };
        nextstable-nixpkgs = import inputs.nextstable-nixpkgs {
          inherit (prev) system;
          inherit (config.nixpkgs) config;
          overlays = overlaysWithoutCustomChannels;
        };
        prevstable-nixpkgs = import inputs.prevstable-nixpkgs {
          inherit (prev) system;
          inherit (config.nixpkgs) config;
          overlays = overlaysWithoutCustomChannels;
        };
        prevstable-neovim = import inputs.prevstable-neovim {
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
        prevstable-gaming = import inputs.prevstable-gaming {
          inherit (prev) system;
          inherit (config.nixpkgs) config;
          overlays = overlaysWithoutCustomChannels;
        };
        prevstable-rubymine = import inputs.prevstable-rubymine {
          inherit (prev) system;
          inherit (config.nixpkgs) config;
          overlays = overlaysWithoutCustomChannels;
        };
      })
    ];
  };
}

