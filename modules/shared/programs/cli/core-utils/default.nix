{ config, pkgs, lib, ... }:

let cfg = config._custom.programs.core-utils;
in {
  options._custom.programs.core-utils.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      aria # like wget but supports torrents, sftp
      atool # file archives (tar, tar+gzip, zip etc)
      file # print filetype
      getopt # fix macos getopt
      git-crypt
      jq # manipulate JSON
      killall
      lsof # print port process
      nix-prefetch-git # get fetchgit hashes
      nix-serve # create a local nix cachix like server
      nurl # get fetchgit hashes
      tree # like ls
      unrar
      unzip
      wget # download http/ftp
      xcp # like cp
      zip
      bc # calculator
      ffmpeg-full # record, convert music/video
      imagemagick # image editor
      silver-searcher # ag, ack like
    ];

    _custom.hm = {
      home.shellAliases = {
        ".." = "cd ..";
        cp = "xcp";
        tree = "tree -a -C -L 1";
        weather = "curl wttr.in";
      };

      programs = {
        # corrects previous console cmd
        thefuck = {
          enable = true;
          enableBashIntegration = false;
          enableZshIntegration = false;
        };

        # completions
        carapace = {
          enable = true;
          enableBashIntegration = false;
          enableZshIntegration = false;
        };

        # locale nix pkgs
        nix-index = {
          enable = false;
          enableZshIntegration = false;
        };

        command-not-found.enable = lib.mkForce false;

        # like tldr
        navi = {
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
  };
}

