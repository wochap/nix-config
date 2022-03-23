{ config, pkgs, lib, inputs, ... }:

let
  localPkgs = import ../packages {
    pkgs = pkgs;
    lib = lib;
  };
  isWayland = config._displayServer == "wayland";

  ani-cli = pkgs.writeShellScriptBin "ani-cli"
    (builtins.readFile "${inputs.ani-cli}/ani-cli");
  mangaflix = pkgs.writeShellScriptBin "mangaflix"
    (builtins.readFile "${inputs.flix-tools}/ManganatoFlix/mangaflix");
  piratebayflix = pkgs.writeShellScriptBin "piratebayflix"
    (builtins.readFile "${inputs.flix-tools}/PirateBayFlix/piratebayflix");
  fontpreview-ueberzug = pkgs.writeShellScriptBin "fontpreview-ueberzug"
    (builtins.readFile "${inputs.fontpreview-ueberzug}/fontpreview-ueberzug");
in {
  config = {
    environment.systemPackages = with pkgs; [
      # TOOLS
      ansible
      aria
      bc # calculator cli
      cached-nix-shell # fast nix-shell scripts
      dos2unix # convert line breaks DOS - mac
      ffmpeg-full # music/video codecs?
      ffmpegthumbnailer
      file # print filetype
      gecode # c++ module?
      git
      git-crypt
      gnumake # make
      gpp # c++ module?, decrypt
      inetutils
      jq # JSON
      killall
      libpwquality # pwscore
      lsof # print port process
      manpages
      mkcert # create certificates (HTTPS)
      ngrok # expose web server
      nix-prefetch-git # get fetchgit hashes
      nix-serve
      openssl
      pup # parse html
      tldr
      tree
      unrar
      unzip
      urlscan
      vim
      watchman # required by react native
      wget
      xcp
      zip

      # DE CLI
      amfora
      gitAndTools.gh
      gotop # monitor system
      lynx

      # APPS CLI
      ani-cli
      cbonsai
      piratebayflix
      speedread
      stripe-cli
      # mangaflix
      # dogecoin

      # APPS
      nyxt
      qutebrowser
      sublime3 # text editor
      tmux
      tty-clock
      zoom-us

      # teamviewer
      # mysql-workbench

    ];
  };
}
