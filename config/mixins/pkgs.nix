{ config, pkgs, inputs, ... }:

let
  ani-cli = pkgs.writeShellScriptBin "ani-cli"
    (builtins.readFile "${inputs.ani-cli}/ani-cli");
in {
  config = {
    environment = {
      systemPackages = with pkgs; [
        # OTHERS
        gecode # c++ module
        gpp # c++ module?, decrypt
        watchman # required by react native

        # CLI TOOLS
        aria # like wget but supports torrents, sftp
        dos2unix # convert line breaks DOS - mac
        file # print filetype
        gcc # GNU compiler collection
        getopt # fix macos getopt
        git-crypt
        gnumake # make
        inetutils # network tools
        jp2a # image to ascii
        jq # manipulate JSON
        killall
        libpwquality # password tools, pwscore
        lsof # print port process
        man-pages
        mkcert # create certificates (HTTPS)
        nix-prefetch-git # get fetchgit hashes
        nix-serve # create a local nix cachix like server
        nurl # get fetchgit hashes
        openssl
        pup # parse html
        tldr # examples of each command
        tree # like ls
        unrar
        unzip
        urlscan # extract urls from emails/txt files
        wget # download http/ftp
        xcp # like cp
        zip

        # CLI APPS
        ansible # automation scripts
        bc # calculator
        clolcat # like cat/bat but with colors
        ffmpeg-full # record, convert music/video
        git
        gitAndTools.gh # github cli
        ngrok # expose web server
        stripe-cli

        # TUI APPS
        amfora # gemini browser
        ani-cli
        cbonsai # print bonsai ascii
        gotop # monitor system
        speedread # read a file, word by word
        tmux # terminal multiplexer
      ];

      shellAliases = {
        cp = "xcp";
        tree = "tree -a -C -L 1";
        weather = "curl wttr.in";
      };
    };
  };
}
