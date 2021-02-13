{ config, pkgs, lib, ... }:

let
  isXorg = config._displayServer == "xorg";
  localPkgs = import ../../packages { pkgs = pkgs; };
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

      # Let Home Manager install and manage itself.
      programs.home-manager.enable = true;

      # Open GTK inspector with Ctrl + Shift + D
      # GTK_DEBUG=interactive <app>
      dconf.settings = {
        "org/gtk/Settings/Debug" = {
          enable-inspector-keybinding = true;
        };
      };

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
        rofi-calc

        # Dev tools
        # docker
        # docker-compose
        gitAndTools.gh
        mysql-workbench
        # nodejs
        postman
        vscode
        # python3
        # To lookup packages for nix, use the following code:
        # nix-env -qaPA 'nixos.nodePackages' | grep -i <npm module>
        # nodePackages.vue-cli
        # python3Packages.dbus-python

        # Apps
        kdeApplications.kdenlive # video editor
        openshot-qt # video editor
        obs-studio # video capture
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

        # Control default apps
        mimeApps.enable = true;
        mimeApps.defaultApplications = {
          "inode/directory" = [ "thunar.desktop" ];
          "text/html" = [ "firefox.desktop" ];
          "x-scheme-handler/about" = [ "firefox.desktop" ];
          "x-scheme-handler/http" = [ "firefox.desktop" ];
          "x-scheme-handler/https" = [ "firefox.desktop" ];
          "x-scheme-handler/mailto" = [ "exo-mail-reader.desktop" ];
          "x-scheme-handler/unknown" = [ "firefox.desktop" ];
          "x-scheme-handler/webcal" = [ "google-chrome.desktop" ];
          "message/rfc822" = [ "userapp-Thunderbird-LAA0Y0.desktop" ];
        };
        mimeApps.associations.added = {
          "image/png" = [ "org.gnome.eog.desktop" ];
          "image/jpeg" = [ "org.gnome.eog.desktop" ];
          "image/svg+xml" = [ "org.gnome.eog.desktop" ];
          "x-scheme-handler/mailto" = [ "userapp-Thunderbird-LAA0Y0.desktop" ];
          "message/rfc822" = [ "userapp-Thunderbird-LAA0Y0.desktop" ];
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
          "Pictures/backgrounds/default.jpeg".source = ../../wallpapers/default.jpeg;
          ".config/Thunar/uca.xml".source = ./dotfiles/Thunar/uca.xml;
          ".config/kitty/kitty.conf".source = ./dotfiles/kitty.conf;
          ".vimrc".source = ./dotfiles/.vimrc;
          # Fix cursor theme
          ".icons/default/index.theme".text = ''
            [icon theme]
            Inherits=capitaine-cursors
          '';
          ".config/nixpkgs/config.nix".text = ''
            { allowUnfree = true; }
          '';
        }
        (lib.mkIf isXorg {
          ".config/polybar/main.ini".source = ./dotfiles/polybar/main.ini;
          ".config/polybar/scripts/get_spotify_status.sh".source = ./dotfiles/polybar/scripts/get_spotify_status.sh;
          ".config/polybar/scripts/scroll_spotify_status.sh".source = ./dotfiles/polybar/scripts/scroll_spotify_status.sh;
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

      programs.zsh = {
        enable = true;
        enableCompletion = true;
        enableAutosuggestions = true;
        oh-my-zsh = {
          enable = true;
          theme = "robbyrussell";
        };
      };

      programs.bash.enable = true;

      programs.rofi = {
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
        temperature = {
          day = 4000;
          night = 3700;
        };
      };

      # notifications
      services.dunst = lib.mkIf isXorg {
        enable = true;
        iconTheme = {
          name = "WhiteSur-dark";
          package = localPkgs.whitesur-dark-icons;
        };
        settings = (import ./dotfiles/dunstrc.nix);
      };

      # screenshot utility
      services.flameshot.enable = isXorg;

      # services.random-background = {
      #   enable = true;
      #   imageDirectory = "%h/Pictures/backgrounds";
      #   interval = "30m";
      # };
    };
  };
}
