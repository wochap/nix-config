# Used by darwin|wayland|xorg config
{ config, pkgs, lib, ... }:

{
  # https://discourse.nixos.org/t/using-mkif-with-nested-if/5221/4
  # https://discourse.nixos.org/t/best-resources-for-learning-about-the-nixos-module-system/1177/4
  # https://nixos.org/manual/nixos/stable/index.html#sec-option-types
  options = {
    _displayServer = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "xorg"; # xorg, wayland, darwin
      description = "Display server type, used by common config files.";
    };
    _isHidpi = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = true;
      description = "Flag for hidpi displays.";
    };
    _userName = lib.mkOption {
      type = lib.types.str;
      default = "gean";
      example = "gean";
      description = "Default user name";
    };
    _homeDirectory = lib.mkOption {
      type = lib.types.str;
      default = "/home/gean";
      example = "/home/gean";
      description = "Path of user home folder";
    };
    _configDirectory = lib.mkOption {
      type = lib.types.str;
      default = "/home/gean/nix-config";
      example = "/home/gean/nix-config";
      description = "Path of config folder";
    };
    _theme = lib.mkOption {
      type = lib.types.attrsOf (lib.types.nullOr lib.types.str);
      default = { };
      example = "{}";
      description = "Theme colors";
    };
  };

  config = {
    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;

    nix = {
      # Enable cachix
      binaryCachePublicKeys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "colemickens.cachix.org-1:bNrJ6FfMREB4bd4BOjEN85Niu8VcPdQe4F4KxVsb/I4="
        "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
      ];
      binaryCaches = [
        "https://cache.nixos.org"
        "https://colemickens.cachix.org"
        "https://nixpkgs-wayland.cachix.org"
      ];
      trustedUsers = [ "@wheel" "root" ];

      # Enable flakes
      package = pkgs.nixUnstable;
      extraOptions = ''
        experimental-features = nix-command flakes recursive-nix
      '';

      gc.automatic = true;

      # settings = {
      #   # Enable cachix
      #   trusted-public-keys = [
      #     "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      #     "colemickens.cachix.org-1:bNrJ6FfMREB4bd4BOjEN85Niu8VcPdQe4F4KxVsb/I4="
      #     "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
      #   ];
      #   substituters = [
      #     "https://cache.nixos.org"
      #     "https://colemickens.cachix.org"
      #     "https://nixpkgs-wayland.cachix.org"
      #   ];
      #
      #   trusted-users = [ "@wheel" "root" ];
      # };
    };

    # Set your time zone.
    time.timeZone = "America/Panama";

    environment = {
      shellAliases = { ll = "ls -l"; };

      # Links those paths from derivations to /run/current-system/sw
      pathsToLink = [ "/share" "/libexec" ];
    };

    # Fix https://discourse.nixos.org/t/normal-users-not-appearing-in-login-manager-lists/4619
    programs.zsh.enable = true;
    programs.fish.enable = true;

    # home-manager options
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = false;
  };
}
