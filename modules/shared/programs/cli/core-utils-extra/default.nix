{ config, pkgs, lib, inputs, ... }:

let cfg = config._custom.programs.core-utils-extra;
in {
  options._custom.programs.core-utils-extra.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {

      home.packages = with pkgs; [
        crudini # edit ini files
        dos2unix # convert line breaks DOS - mac
        inetutils # network tools
        libpwquality # password tools, pwscore
        man-pages
        openssl
        pup # parse html
        speedread # read a file, word by word
        tealdeer # examples of each command
        portal # transfer files
        age # encrypt files
        dust # disk usage
        entr # run something on file change
        qpdf # removes password of pdf
        reader # blog post reader
        pastel # color utils

        chawan # tui browser
        termshark # tui wireshark
        gdu # tui disk usage

        asciinema # record terminal
        asciinema-agg # generate GIF
        asciinema-scenario # generate recording from txt files

        cbonsai # print bonsai ascii
        clolcat # like cat/bat but with colors
        cowsay # print animals with message
        fortune # print fortune text
        jp2a # image to ascii

        inputs.lobster.packages.${system}.lobster
      ];
    };
  };
}
