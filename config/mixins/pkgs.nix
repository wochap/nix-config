{ config, pkgs, lib, inputs, ... }:

let
  ani-cli = pkgs.writeShellScriptBin "ani-cli"
    (builtins.readFile "${inputs.ani-cli}/ani-cli");
  mangaflix = pkgs.writeShellScriptBin "mangaflix"
    (builtins.readFile "${inputs.flix-tools}/ManganatoFlix/mangaflix");
  piratebayflix = pkgs.writeShellScriptBin "piratebayflix"
    (builtins.readFile "${inputs.flix-tools}/PirateBayFlix/piratebayflix");
in {
  config = {
    environment.systemPackages = with pkgs; [
      # CLI TOOLS
      ansible
      aria
      bc # calculator cli
      dos2unix # convert line breaks DOS - mac
      ffmpeg-full # music/video codecs?
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
      lolcat # rainbow
      lsof # print port process
      man-pages
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
      tmux
      # mangaflix
      # dogecoin

    ];
  };
}
