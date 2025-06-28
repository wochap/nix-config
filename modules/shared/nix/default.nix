{ config, pkgs, lib, inputs, ... }:

let inherit (config._custom.globals) configDirectory;
in {
  config = {
    environment.systemPackages = with pkgs; [ nix-tree ];

    nix = {
      gc.automatic = lib.mkDefault false;

      # Enable flakes
      # use nix 2.18.1 until PR is merge https://github.com/NixOS/nix/pull/9723
      # PR fixes the following issues:
      # https://github.com/nix-community/home-manager/issues/4692
      # https://github.com/NixOS/nix/issues/9579
      package = pkgs.prevstable-nix.nixUnstable;
      extraOptions = ''
        experimental-features = nix-command flakes recursive-nix
      '';

      # pin the registry to avoid downloading and evaling a new nixpkgs version every time
      registry = lib.mapAttrs (_: v: { flake = v; }) inputs;
      # set the path for channels compat
      nixPath =
        lib.mapAttrsToList (key: _: "${key}=flake:${key}") config.nix.registry;

      settings = {
        # Enable flakes
        experimental-features = [ "nix-command" "flakes" "recursive-nix" ];

        # Auto clear nixos store
        auto-optimise-store = false;

        # Enable cachix
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
          "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
          "nixpkgs-python.cachix.org-1:hxjI7pFxTyuTHn2NkvWCrAUcNZLNS3ZAvfYNuYifcEU="
          "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
          "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
          "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
        ];
        substituters = [
          "https://cache.nixos.org"
          "https://nix-community.cachix.org"
          "https://cuda-maintainers.cachix.org"
          "https://nixpkgs-wayland.cachix.org"
          "https://hyprland.cachix.org"
          "https://nixpkgs-python.cachix.org"
          "https://nix-gaming.cachix.org"
          "https://cache.garnix.io"
          "https://devenv.cachix.org"
        ];

        trusted-users = [ "@wheel" "root" ];

        system-features = [
          # default values
          # "benchmark"
          # "nixos-test"
          "big-parallel"
          "kvm"
          "recursive-nix"
        ];
      };
    };

    programs.nh = {
      enable = true;
      clean.enable = false;
      flake = configDirectory;
    };
  };
}

