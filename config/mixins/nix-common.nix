# Used by darwin|wayland|xorg config
{ config, pkgs, lib, inputs, ... }:

let userName = config._userName;
in {

  config = {
    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;
    nixpkgs.config.permittedInsecurePackages =
      [ "nodejs-14.21.3" "openssl-1.1.1u" "openssl-1.1.1v" ];

    nix = {
      # Enable flakes
      package = pkgs.nixUnstable;
      extraOptions = ''
        experimental-features = nix-command flakes recursive-nix
      '';

      gc.automatic = true;

      # pin the registry to avoid downloading and evaling a new nixpkgs version every time
      registry = lib.mapAttrs (_: v: { flake = v; }) inputs;
      # set the path for channels compat
      nixPath =
        lib.mapAttrsToList (key: _: "${key}=flake:${key}") config.nix.registry;

      settings = {
        # Enable cachix
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "colemickens.cachix.org-1:bNrJ6FfMREB4bd4BOjEN85Niu8VcPdQe4F4KxVsb/I4="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
          "nixpkgs-python.cachix.org-1:hxjI7pFxTyuTHn2NkvWCrAUcNZLNS3ZAvfYNuYifcEU="
          "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
        ];
        substituters = [
          "https://cache.nixos.org"
          "https://colemickens.cachix.org"
          "https://nix-community.cachix.org"
          "https://nixpkgs-wayland.cachix.org"
          "https://hyprland.cachix.org"
          "https://nixpkgs-python.cachix.org"
          "https://cache.garnix.io"
        ];

        trusted-users = [ "@wheel" "root" ];
      };
    };

    # Set your time zone.
    time.timeZone = lib.mkDefault "America/Panama";

    environment = {
      shellAliases = {
        cp = "xcp";
        tree = "tree -a -C -L 1";

        weather = "curl wttr.in";
        ttc = ''tty-clock -c -C 2 -r -f "%A, %B %d"'';
      };

      # Links those paths from derivations to /run/current-system/sw
      pathsToLink = [ "/share" "/libexec" ];
    };

    # Fix https://discourse.nixos.org/t/normal-users-not-appearing-in-login-manager-lists/4619
    programs.zsh.enable = true;
    programs.fish.enable = true;

    # home-manager options
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = false;

    home-manager.users.${userName} = {
      # Let Home Manager install and manage itself.
      programs.home-manager.enable = true;

      # Setup dotfiles
      home.file = {
        ".config/nixpkgs/config.nix".text = ''
          { allowUnfree = true; }
        '';
      };

      programs.bash.enable = true;
      programs.zsh.enable = true;
      programs.fish.enable = true;
    };
  };
}
