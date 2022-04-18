# Used by darwin|wayland|xorg config
{ config, pkgs, lib, ... }:

let theme = config._theme;
in {
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
    _isNvidia = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = true;
      description = "Flag for devices with nvidia.";
    };
  };

  config = {
    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;

    nix = {
      # Enable flakes
      package = pkgs.nixUnstable;
      extraOptions = ''
        experimental-features = nix-command flakes recursive-nix
      '';

      gc.automatic = true;

      # Enable cachix
      binaryCachePublicKeys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "colemickens.cachix.org-1:bNrJ6FfMREB4bd4BOjEN85Niu8VcPdQe4F4KxVsb/I4="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
      ];
      binaryCaches = [
        "https://cache.nixos.org"
        "https://colemickens.cachix.org"
        "https://nix-community.cachix.org"
        "https://nixpkgs-wayland.cachix.org"
      ];
      trustedUsers = [ "@wheel" "root" ];

      # settings = {
      #   # Enable cachix
      #   trusted-public-keys = [
      #     "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      #     "colemickens.cachix.org-1:bNrJ6FfMREB4bd4BOjEN85Niu8VcPdQe4F4KxVsb/I4="
      #     "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      #     "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
      #   ];
      #   substituters = [
      #     "https://cache.nixos.org"
      #     "https://colemickens.cachix.org"
      #     "https://nix-community.cachix.org"
      #     "https://nixpkgs-wayland.cachix.org"
      #   ];
      #
      #   trusted-users = [ "@wheel" "root" ];
      # };
    };

    # Set your time zone.
    time.timeZone = "America/Panama";

    environment = {
      shellAliases = {
        cp = "xcp";
        tree = "tree -a -C -L 1";

        weather = "curl wttr.in";
        ttc = ''tty-clock -c -C 2 -r -f "%A, %B %d"'';
        yt =
          "youtube-dl --extract-audio --add-metadata --xattrs --embed-thumbnail --audio-quality 0 --audio-format mp3";
        ytv =
          "youtube-dl --merge-output-format mp4 -f 'bestvideo+bestaudio[ext=m4a]/best' --embed-thumbnail --add-metadata";
        fp =
          "fontpreview-ueberzug -b ${theme.background} -f ${theme.foreground}";
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
  };
}
