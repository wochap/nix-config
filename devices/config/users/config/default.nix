{ config, pkgs, lib, ... }:

{
  imports = [
    ./git.nix
    ./polybar.nix
  ];

  config = {
    home-manager.users.gean = {
      # This value determines the Home Manager release that your
      # configuration is compatible with. This helps avoid breakage
      # when a new Home Manager release introduces backwards
      # incompatible changes.
      #
      # You can update Home Manager without changing this value. See
      # the Home Manager release notes for a list of state version
      # changes in each release.
      home.stateVersion = "21.03";

      # Let Home Manager install and manage itself.
      programs.home-manager.enable = true;

      # Allow unfree packages
      nixpkgs.config.allowUnfree = true;

      # User packages
      home.packages = with pkgs; [
        # DE apps
        nitrogen # wallpaper manager
        # copyq # clipboard manager
        clipmenu

        # Dev tools
        gitAndTools.gh
        docker-compose
        docker
        mysql-workbench
        postman
        vscode
        rofi # app launcher

        # Apps
        firefox
        brave
        google-chrome
        nix-prefetch-git
        mpv # video player
        slack
      ];

      # Environment variables to always set at login.
      home.sessionVariables = {
        BROWSER = "firefox";
        TERMINAL = "kitty";
      };

      # Add config files to home folder
      home.file = {
        ".config/polybar".source = ./dotfiles/polybar;
        ".config/Thunar/thunarrc".source = ./dotfiles/thunarrc;
        ".cache/wal/colors-kitty.conf".source = ./dotfiles/pywal/colors-kitty.conf;
        ".cache/wal/colors-rofi-dark.rasi".source = ./dotfiles/pywal/colors-rofi-dark;
        ".cache/wal/colors.sh".source = ./dotfiles/pywal/colors.sh;
        ".config/kitty/kitty.conf".source = ./dotfiles/kitty.conf;
        ".vimrc".source = ./dotfiles/.vimrc;
        ".config/rofi/config.rasi".source = ./dotfiles/rofi.rasi;
        ".config/nixpkgs/config.nix".text = ''
          { allowUnfree = true; }
        '';
      };

      programs.fish = {
        enable = true;
        plugins = [
          {
            name = "z";
            src = pkgs.fetchFromGitHub {
              owner = "jethrokuan";
              repo = "z";
              rev = "ddeb28a7b6a1f0ec6dae40c636e5ca4908ad160a";
              sha256 = "0c5i7sdrsp0q3vbziqzdyqn4fmp235ax4mn4zslrswvn8g3fvdyh";
            };
          }
        ];
      };

      programs.bash = {
        enable = true;
      };

      programs.vim = {
        enable = true;
        settings = {
          relativenumber = true;
          number = true;
        };
      };

      services.gpg-agent = {
        enable = true;
        enableSshSupport = true;
        defaultCacheTtl = 1800;
      };

      services.redshift = {
        enable = true;
        latitude = "-12.051408";
        longitude = "-76.922124";
      };

      services.dunst = {
        enable = true;
      };

      services.flameshot.enable = true;
    };
  };
}
