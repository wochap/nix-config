{ config, lib, pkgs, inputs, system, ... }:

let
  cfg = config._custom.programs.others;
  ani-cli = pkgs.writeShellScriptBin "ani-cli"
    (builtins.readFile "${inputs.ani-cli}/ani-cli");
in {
  options._custom.programs.others.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        # OTHERS
        gecode # c++ module
        gpp # c++ module?, decrypt
        watchman # required by react native

        # CLI TOOLS
        aria # like wget but supports torrents, sftp
        atool # file archives (tar, tar+gzip, zip etc)
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
        tealdeer # examples of each command
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
        silver-searcher # ag, ack like
        stripe-cli

        # TUI APPS
        ani-cli
        cbonsai # print bonsai ascii
        gotop # monitor system
        inputs.lobster.packages.${system}.lobster
        speedread # read a file, word by word
      ];

      shellAliases = {
        ".." = "cd ..";
        cp = "xcp";
        tree = "tree -a -C -L 1";
        weather = "curl wttr.in";
      };
    };

    _custom.hm = {
      programs.thefuck.enable = true; # corrects previous console cmd
      programs.thefuck.enableBashIntegration = false;
      programs.carapace.enable = true; # completions
      programs.carapace.enableBashIntegration = false;
      programs.nix-index.enable = false; # locale nix pkgs
      programs.command-not-found.enable = lib.mkForce false;
      programs.navi = { # like tldr
        enable = true;
        settings = {
          finder.command = "fzf";
          shell.command = "bash";
        };
        enableBashIntegration = false;
        enableZshIntegration = config._custom.programs.zsh.enable;
      };
    };
  };
}

