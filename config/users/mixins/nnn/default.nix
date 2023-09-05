{ config, pkgs, lib, inputs, ... }:

let
  isDarwin = config._displayServer == "darwin";
  userName = config._userName;
in {
  config = {
    environment = {
      variables = {
        NNN_TRASH = "1";
        NNN_FIFO = "/tmp/nnn.fifo";
        SPLIT = "v";
        KITTY_LISTEN_ON = "unix:/tmp/kitty";
      };
    };

    home-manager.users.${userName} = {
      programs.nnn = {
        enable = true;
        package = pkgs.nnn.override { withNerdIcons = true; };
        extraPackages = with pkgs;
          [
            (writeShellScriptBin "scope.sh"
              (builtins.readFile "${inputs.ranger}/ranger/data/scope.sh"))
            libarchive
            bat
            exa
            fzf
            mediainfo
          ] ++ lib.optionals (!isDarwin) [ ffmpegthumbnailer sxiv fontpreview ];
        plugins = {
          mappings = {
            c = "fzcd";
            f = "finder";
            o = "fzopen";
            p = "preview-tui";
            t = "nmount";
            v = "imgview";
          };
          src = "${inputs.nnn}/plugins";
        };
      };
    };
  };
}
