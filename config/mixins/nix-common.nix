# Used by darwin|wayland|xorg config
{ config, pkgs, lib, ... }:

let theme = config._theme;
in {

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

      settings = {
        # Enable cachix
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "colemickens.cachix.org-1:bNrJ6FfMREB4bd4BOjEN85Niu8VcPdQe4F4KxVsb/I4="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        ];
        substituters = [
          "https://cache.nixos.org"
          "https://colemickens.cachix.org"
          "https://nix-community.cachix.org"
          "https://nixpkgs-wayland.cachix.org"
          "https://hyprland.cachix.org"
        ];

        trusted-users = [ "@wheel" "root" ];
      };
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
