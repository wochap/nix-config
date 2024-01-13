{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.tui.nnn;
  isDarwin = config._displayServer == "darwin";
  userName = config._userName;
in {
  options._custom.tui.nnn = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    environment = {
      variables = {
        NNN_TRASH = "1";
        NNN_FIFO = "/tmp/nnn.fifo";
        NNN_SPLIT = "v";
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
            eza
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
