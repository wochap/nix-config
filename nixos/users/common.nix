{ config, pkgs, hostName ? "unknown", ... }:

{
  imports = [
    ./polybar.nix
    ./git.nix
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

  home.sessionVariables = {
    # EDITOR = "nvim";
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
