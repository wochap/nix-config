{ config, pkgs, hostName ? "unknown", ... }:

{
  imports = [
    ./polybar.nix
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Add config files to home folder
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

  # User packages
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
    gitAndTools.gh

    # Apps
    firefox
    pantheon.elementary-icon-theme
    vscode
    nix-prefetch-git
  ];

  home.sessionVariables = {
    # EDITOR = "nvim";
  };

  # Generates ~/.gitconfig
  programs.git = {
    package = pkgs.gitAndTools.gitFull;
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
      pull.rebase = "false";
    };
  };

  programs.fish = {
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
