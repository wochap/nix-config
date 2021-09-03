{ config, pkgs, lib, ... }:

let
  doom-emacs-src = builtins.fetchTarball {
    # master branch
    url = https://github.com/vlaci/nix-doom-emacs/archive/fee14d217b7a911aad507679dafbeaa8c1ebf5ff.tar.gz;
    sha256 = "1g0izscjh5nv4n0n1m58jc6z27i9pkbxs17mnb05a83ffdbmmva6";
    # develop branch
    # url = https://github.com/vlaci/nix-doom-emacs/archive/1020f27f1fab123f0ce3ed5f6e9c0637d888c884.tar.gz;
    # sha256 = "1fgrxzmkbh699ah1sqr0937bysfx0v1q805k6kpjjfwbrfn6113h";
  };
  doom-emacs = pkgs.callPackage doom-emacs-src {
    doomPrivateDir = ./dotfiles/doom.d;
    # emacsPackagesOverlay = self: super: {
    #   magit-delta = super.magit-delta.overrideAttrs (esuper: {
    #     buildInputs = esuper.buildInputs ++ [ pkgs.git ];
    #   });
    # };
  };
in
{
  config = {
    environment.systemPackages = with pkgs; [
      doom-emacs
    ];
    services.emacs = {
      enable = true;
      package = doom-emacs;  # use programs.emacs.package instead if using home-manager
    };
    fonts = {
      fonts = with pkgs; [
        emacs-all-the-icons-fonts
      ];
    };

    home-manager.users.gean = {
      # home.packages = [
      #   doom-emacs
      # ];
      home.file.".emacs.d/init.el".text = ''
        (load "default.el")
      '';
      # home.file = {
      #   "doom.d".source = ./dotfiles/doom.d;
      # };
    };
  };
}
