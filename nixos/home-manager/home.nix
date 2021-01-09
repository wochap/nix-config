{ config, pkgs, hostName ? "unknown", ... }:

{
  imports = [
    ./polybar.nix
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  services.xserver.windowManager.bspwm.enable = true;

  xsession = {
    enable = true;
    windowManager.command = "bspwm";
    windowManager.bspwm = {
      enable = true;
      settings = {
        border_width = 2;
        window_gap = 12;
        split_ratio = 0.52;
        borderless_monocle = true;
        gapless_monocle = true;
      };
      monitors = {
        "HDMI-0" = [ "web" "terminal" "III" "IV" ];
        "default" = [ "III" "IV" ];
      };
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  home.file = {
    ".config/nixpkgs/config.nix".text = ''
      { allowUnfree = true; }
    '';
    
    ".vimrc".text = ''
      set tabstop = 2
      set softtabstop = 2
      set shiftwidth = 2
      set expandtab
    '';

    # ".config/kitty/kitty.conf".text = ''
    #   shell fish
    # '';
  };

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "gean";
  home.homeDirectory = "/home/gean";

  home.packages = with pkgs; [
    # Basic tools
    htop
    wget
    radeontop # like htop for gpu

    # DE
    nitrogen # wallpaper manager
    copyq # clipboard manager
    xfce.thunar # file manager

    # Dev tools
    gnumake # make
    # gitAndTools.gh

    # Apps
    firefox
    pantheon.elementary-icon-theme
    vscode
    nix-prefetch-git
  ];

  home.sessionVariables = {
    # EDITOR = "nvim";
  };

  programs.git = {
    # package = pkgs.gitAndTools.gitFull;
    enable = true;
    userName = "wochap";
    userEmail = "gean.marroquin@gmail.com";
    aliases = {
      co = "checkout";
      ci = "commit";
      st = "status";
    };
    extraConfig = {
      core.editor = "vim";
      # protocol.keybase.allow = "always";
      # credential.helper = "store --file ~/.git-credentials";
      pull.rebase = "false";
    };
  };

  programs.rofi = {
    enable = true;
  };

  programs.fish = {
    enable = true;
  };
  
  programs.vim = {
    enable = true;
    # extraConfig = builtins.readFile vim/vimrc;
    settings = {
      relativenumber = true;
      number = true;
    };
  };

  #programs.firefox = {
  #  enable = true;
  #  profiles = {
  #    myprofile = {
  #      settings = {
  #        "general.smoothScroll" = true;
  #      };
  #    };
  #  };
  #};

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    defaultCacheTtl = 1800;
  };

  services.sxhkd = {
    enable = true;
    keybindings = {
      "super + Return" = "kitty";
      "super + @space" = "rofi -show run";
      "super + q" = "bspc node -{c, k}";
    };
  };

  services.picom = {
    enable = true;
    inactiveOpacity = "0.5";
    activeOpacity = "1"; #"0.90";
    #opacityRule = [ "100:class_g = 'Google-chrome'" "100:class_g = 'Alacritty'" "60:class_g = 'rofi'" ];
    fade = true;
    vSync = true;
    shadow = true;
    fadeDelta = 4 ;
    fadeSteps = ["0.02" "0.02"];
    blur = true;
    backend = "glx";
    inactiveDim = "0.2";
    extraOptions = ''
      frame-opacity = 1;
      blur-background = true;
      blur-kern = "7x7box";
      blur-background-exclude = [];
    '';
  };

  services.redshift = {
    enable = true;
    latitude = "-12.051408";
    longitude = "-76.922124";
  };

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "21.03";
}
