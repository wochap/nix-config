{ config, pkgs, lib, ... }:

let
  isXorg = config._displayServer == "xorg";
in
{
  imports = [
    ./git.nix
    ./gtk.nix
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

      home.extraProfileCommands = ''
        if [[ -d "$out/share/applications" ]] ; then
          ${pkgs.desktop-file-utils}/bin/update-desktop-database $out/share/applications
        fi
      '';

      # User packages
      home.packages = with pkgs; [
        # DE apps
        nitrogen # wallpaper manager
        clipmenu # clipboard manager
        rofi # app launcher

        # Dev tools
        gitAndTools.gh
        docker-compose
        docker
        mysql-workbench
        postman
        vscode
        nodejs
        # To lookup packages for nix, use the following code:
        # nix-env -qaPA 'nixos.nodePackages' | grep -i <npm module>
        nodePackages.vue-cli

        # Apps
        kdeApplications.kdenlive
        openshot-qt
        obs-studio
        firefox
        brave
        google-chrome
        nix-prefetch-git
        mpv # video player
        slack
      ];

      home.sessionVariables = {
        BROWSER = "firefox";
        TERMINAL = "kitty";
      };

      # Edit home files
      xdg = {
        enable = true;
        dataFile = {
          "icons/hicolor/128x128/apps/code.png".source = ./icons/vscode/icon-128.png;
          "icons/hicolor/128x128/apps/d3lphin.png".source = ./icons/system-file-manager/icon-128.png;
          "icons/hicolor/128x128/apps/dde-file-manager.png".source = ./icons/system-file-manager/icon-128.png;
          "icons/hicolor/128x128/apps/kitty.png".source = ./icons/terminal/icon-128.png;
          "icons/hicolor/128x128/apps/org.xfce.filemanager.png".source = ./icons/system-file-manager/icon-128.png;
          "icons/hicolor/128x128/apps/system-file-manager.png".source = ./icons/system-file-manager/icon-128.png;
          "icons/hicolor/128x128/apps/thunar.png".source = ./icons/system-file-manager/icon-128.png;
          "icons/hicolor/128x128/apps/xarchiver.png".source = ./icons/ark/icon-128.png;
          "icons/hicolor/128x128/apps/xfce-filemanager.png".source = ./icons/system-file-manager/icon-128.png;
        };

        # Control default apps
        mimeApps.enable = true;
        mimeApps.defaultApplications = {
          "inode/directory" = [ "thunar.desktop" ];
          "text/html" = [ "firefox.desktop" ];
          "x-scheme-handler/http" = [ "firefox.desktop" ];
          "x-scheme-handler/https" = [ "firefox.desktop" ];
          "x-scheme-handler/about" = [ "firefox.desktop" ];
          "x-scheme-handler/unknown" = [ "firefox.desktop" ];
        };
        mimeApps.associations.added = {
          "image/png" = [ "org.nomacs.ImageLounge.desktop" ];
          "image/jpeg" = [ "org.nomacs.ImageLounge.desktop" ];
          "image/svg+xml" = [ "org.nomacs.ImageLounge.desktop" ];
        };

        # Edit linked files
        configFile = {
          # HACK: Load fish theme
          "fish/conf.d/plugin-eclm.fish".text = lib.mkAfter ''
            for f in $plugin_dir/*.fish
              source $f
            end
          '';

          "fish/config.fish".text = lib.mkAfter ''
            set fish_greeting
          '';
        };
      };

      # Add config files to home folder
      home.file = {
        ".background-image".source = ../../wallpapers/default.jpeg;
        ".config/polybar/main.ini".source = lib.mkIf isXorg ./dotfiles/polybar/main.ini;
        ".config/polybar/modules.ini".source = lib.mkIf isXorg ./dotfiles/polybar/modules.ini;
        ".config/Thunar/thunarrc".source = ./dotfiles/thunarrc;
        ".config/kitty/kitty.conf".source = ./dotfiles/kitty.conf;
        ".vimrc".source = ./dotfiles/.vimrc;
        ".config/rofi/config.rasi".source = lib.mkIf isXorg ./dotfiles/rofi.rasi;
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
              # get sha256 with:
              # shasum -a 256 fragbuilder-1.0.1.tar.gz
              # nix-hash --flat --base32 --type sha256 https://github.com/ipatch/theme-neolambda/archive/7dc83a021ac8b3fa3c10f7ebf20156c0da931170.tar.gz
              sha256 = "0c5i7sdrsp0q3vbziqzdyqn4fmp235ax4mn4zslrswvn8g3fvdyh";
            };
          }
          {
            name = "eclm";
            src = pkgs.fetchFromGitHub {
              owner = "oh-my-fish";
              repo = "theme-eclm";
              rev = "bd9abe5c5d0490a0b16f2aa303838a2b2cc98844";
              sha256 = "051wzwn4wr53mq27j1hra7y84y3gyqxgdgg2rwbc5npvbgvdkr09";
            };
          }
        ];
      };

      programs.bash.enable = true;

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
        temperature = {
          day = 4000;
          night = 3700;
        };
      };

      services.dunst = lib.mkIf isXorg {
        enable = true;
        settings = (import ./dotfiles/dunstrc.nix);
      };

      services.flameshot.enable = isXorg;

      services.picom = lib.mkIf isXorg {
        # Reduces screen tearing
        enable = true;
        blur = true;
        blurExclude = [];
        experimentalBackends = true;
        vSync = true;
        backend = "glx";
        refreshRate = 60;
        shadowExclude = [];
        fadeExclude = [
          "name ~= 'polybar'"
          "name ~= 'alttab'"
          "name ~= 'rofi'"
        ];
        fade = true;
        shadow = true;
        extraOptions = ''
          blur-method = "gaussian";
          blur-size = 2;
          blur-deviation = 5.0;
        '';
      };
    };
  };
}
