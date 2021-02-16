{ config, pkgs, lib, ... }:

let
  isXorg = config._displayServer == "xorg";
  localPkgs = import ../../packages { pkgs = pkgs; };
in
{
  imports = [
    ./firefox.nix
    ./fish.nix
    ./git.nix
    ./gtk.nix
    ./picom.nix
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
        gitAndTools.gh
        mysql-workbench
        postman
        vscode

        # Apps
        kdeApplications.kdenlive # video editor
        openshot-qt # video editor
        obs-studio # video capture
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
        QT_FONT_DPI = "96";
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
      };

      # Add config files to home folder
      home.file = lib.mkMerge [
        {
          ".config/eww".source = ./dotfiles/eww;
          ".config/zathura/zathurarc".source = ./dotfiles/zathurarc;
          ".config/betterlockscreenrc".source = ./dotfiles/betterlockscreenrc;
          "Pictures/backgrounds/default.jpeg".source = ../../assets/wallpaper.jpg;
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
          ".config/rofi-theme.rasi".source = ./dotfiles/rofi-theme.rasi;
        })
      ];

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
          name = "Papirus";
          package = pkgs.papirus-icon-theme;
          # TODO: add missing icons to WhiteSur-dark
          # name = "WhiteSur-dark";
          # package = localPkgs.whitesur-dark-icons;
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
