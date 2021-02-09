{ config, pkgs, lib, ... }:

let
  isXorg = config._displayServer == "xorg";
in
{
  imports = [
    ./git.nix
    ./gtk.nix
    ./polybar.nix
    ./picom.nix
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

      # Open GTK inspector with Ctrl + Shift + D
      # GTK_DEBUG=interactive <app>
      dconf.settings = {
        "org/gtk/Settings/Debug" = {
          enable-inspector-keybinding = true;
        };
      };

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
        rofi-calc

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
        QT_AUTO_SCREEN_SCALE_FACTOR = "1";
      };

      # Edit home files
      xdg = {
        enable = true;
        dataFile = {
          # xprop to get app class name
          "icons/hicolor/128x128/apps/code.png".source = ./icons/vscode/icon-128.png;
          "icons/hicolor/128x128/apps/kitty.png".source = ./icons/terminal/icon-128.png;
          "icons/hicolor/128x128/apps/org.gnome.Nautilus.png".source = ./icons/system-file-manager/icon-128.png;
          "icons/hicolor/128x128/apps/xarchiver.png".source = ./icons/ark/icon-128.png;
        };

        # Control default apps
        mimeApps.enable = true;
        mimeApps.defaultApplications = {
          "inode/directory" = [ "org.gnome.Nautilus.desktop" ];
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

          "fish/config.fish".text = lib.mkAfter (builtins.readFile ./dotfiles/config.fish);
        };
      };

      # Add config files to home folder
      home.file = lib.mkMerge [
        {
          ".config/eww".source = ./dotfiles/eww;
          ".config/zathura/zathurarc".source = ./dotfiles/zathurarc;
          ".config/betterlockscreenrc".source = ./dotfiles/betterlockscreenrc;
          ".background-image".source = ../../wallpapers/default.jpeg;
          ".config/Thunar/thunarrc".source = ./dotfiles/Thunar/thunarrc;
          ".config/Thunar/uca.xml".source = ./dotfiles/Thunar/uca.xml;
          ".config/kitty/kitty.conf".source = ./dotfiles/kitty.conf;
          ".vimrc".source = ./dotfiles/.vimrc;
          ".config/nixpkgs/config.nix".text = ''
            { allowUnfree = true; }
          '';
        }
        (lib.mkIf isXorg {
          ".config/polybar/main.ini".source = ./dotfiles/polybar/main.ini;
          ".config/rofi-theme.rasi".source = ./dotfiles/rofi-theme.rasi;
        })
      ];

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
        iconTheme = {
          package = pkgs.papirus-icon-theme;
          name = "Papirus";
        };
        settings = (import ./dotfiles/dunstrc.nix);
      };

      services.flameshot.enable = isXorg;
    };
  };
}
