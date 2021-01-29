{ config, pkgs, lib, ... }:

{
  imports = [
    ./git.nix
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # User packages
  home.packages = with pkgs; [
    # Basic tools
    htop
    gotop
    wget
    # radeontop # like htop for amd gpu

    # DE apps
    pywal # theme color generator
    # volumeicon

    # Dev tools
    gitAndTools.gh
    docker-compose
    docker
    mysql-workbench
    postman
    vscode

    # Apps
    firefox
    google-chrome
    nix-prefetch-git
    mpv # video player
    slack
    pulsemixer
  ];

  # Environment variables to always set at login.
  home.sessionVariables = {
    # Force GTK to use wayland
    GDK_BACKEND = "wayland";
    CLUTTER_BACKEND = "wayland";

    # Force firefox to use wayland
    MOZ_ENABLE_WAYLAND = "1";

    BROWSER = "firefox";
    TERMINAL = "kitty";
  };
  home.sessionVariables = lib.mkIf (config.networking.hostName == "vb") {
    # Fix wayfire blackscreen
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  # Add config files to home folder
  home.file = {
    ".config/wayfire.ini".source = ../../dotfiles/wayfire.ini;
    ".vimrc".source = ../../dotfiles/.vimrc;
    # ".config/kitty/kitty.conf".source = ../../dotfiles/kitty.conf;
    ".bashrc".text = ''
      exec ${config.programs.fish.package}/bin/fish
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

  # services.redshift = {
  #   enable = true;
  #   latitude = "-12.051408";
  #   longitude = "-76.922124";
  # };

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
