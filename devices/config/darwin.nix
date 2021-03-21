{ config, pkgs, ... }:

let
  localPkgs = import ./packages { pkgs = pkgs; };
  home-manager = builtins.fetchGit {
    url = "https://github.com/nix-community/home-manager.git";
    rev = "22f6736e628958f05222ddaadd7df7818fe8f59d";
    ref = "release-20.09";
  };
in
{
  imports = [
    # Install home-manager
    (import "${home-manager}/nixos")

    ./users/gean.nix
  ];

  config = {
    _displayServer = "darwin";

    environment = {
      etc = {
        "open_url.sh" = {
          source = ./scripts/open_url.sh;
          mode = "0755";
        };
      };
      shellAliases = {
        gc = "git clone";
        glo = "git pull origin";
        gpo = "git push origin";
        ll = "ls -l";
        open = "xdg-open";
      };
    };

    fonts = {
      enableFontDir = true;
      fonts = with pkgs; [
        corefonts # basic fonts for office
        fira-code
        font-awesome
        font-awesome_4
        material-icons
        noto-fonts
        noto-fonts-cjk
        noto-fonts-emoji
        open-sans
        roboto
        roboto-slab
        siji
        terminus_font

        (nerdfonts.override {
          fonts = [
            "FiraCode"
            "FiraMono"
            "Hack"
            "Iosevka"
          ];
        })
      ];
    };

    # Links those paths from derivations to /run/current-system/sw
    environment.pathsToLink = [
      "/share/zsh"
      "/libexec"
    ];

    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.users.gean = {
      shell = pkgs.zsh;
      uid = 1000;
      home = "/home/gean";
    };

    # Fix https://discourse.nixos.org/t/normal-users-not-appearing-in-login-manager-lists/4619
    programs.zsh.enable = true;
    programs.fish.enable = true;
  };
}
