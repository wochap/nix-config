{ config, pkgs, lib, ... }:

let
  isXorg = config._displayServer == "xorg";
  localPkgs = import ../../packages { pkgs = pkgs; };
in
{
  imports = [
    ./mixins/firefox.nix
    ./mixins/fish.nix
    ./mixins/git.nix
    ./mixins/gtk.nix
    ./mixins/picom.nix
    ./mixins/polybar.nix
    ./mixins/zsh.nix
    ./mixins/mime-apps.nix
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

      # https://github.com/rycee/home-manager/blob/master/modules/targets/generic-linux.nix#blob-path
      targets.genericLinux.enable = true;
      targets.genericLinux.extraXdgDataDirs = [
        "/usr/share"
        "/usr/local/share"
      ];

      # Let Home Manager install and manage itself.
      programs.home-manager.enable = true;

      # Open GTK inspector with Ctrl + Shift + D
      # GTK_DEBUG=interactive <app>
      dconf.settings = {
        "org/gtk/Settings/Debug" = {
          enable-inspector-keybinding = true;
        };
      };

      home.extraProfileCommands = ''
        if [[ -d "$out/share/applications" ]] ; then
          ${pkgs.desktop-file-utils}/bin/update-desktop-database $out/share/applications
        fi
      '';

      home.packages = with pkgs; [
        rofi-calc
      ];

      home.sessionVariables = {
        # BROWSER = "/etc/open_url.sh";
        NIXOS_CONFIG = "/home/gean/nix-config/devices/desktop.nix";
        OPENER = "xdg-open";
        READER = "zathura";
        TERMINAL = "kitty";
        VIDEO = "mpv";
      };

      # Edit home files
      xdg.enable true;

      # Add config files to home folder
      home.file = lib.mkMerge [
        {
          ".config/sublime-text-3/Packages/User/Default (Linux).sublime-keymap".source = ./dotfiles/linux.sublime-keymap.json;
          ".ssh/config".source = ./dotfiles/ssh-config;
          ".config/eww".source = ./dotfiles/eww;
          ".config/zathura/zathurarc".source = ./dotfiles/zathurarc;
          ".config/betterlockscreenrc".source = ./dotfiles/betterlockscreenrc;
          ".config/mpv/mpv.conf".source = ./dotfiles/mpv.conf;
          "Pictures/backgrounds/default.jpeg".source = ../../assets/wallpaper.jpg;
          ".config/Thunar/uca.xml".source = ./dotfiles/Thunar/uca.xml;
          ".config/kitty/kitty.conf".source = ./dotfiles/kitty.conf;
          # ".config/kitty/kitty-session-tripper.conf".source = ./dotfiles/kitty-session-tripper.conf;
          ".vimrc".source = ./dotfiles/.vimrc;
          # Fix cursor theme
          ".icons/default".source = "${pkgs.capitaine-cursors}/share/icons/capitaine-cursors";
          ".config/nixpkgs/config.nix".text = ''
            { allowUnfree = true; }
          '';
        }
        (lib.mkIf isXorg {
          ".config/rofi-theme.rasi".source = ./dotfiles/rofi-theme.rasi;
        })
      ];

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
