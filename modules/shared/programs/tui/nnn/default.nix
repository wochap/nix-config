{ config, pkgs, lib, ... }:

let
  cfg = config._custom.tui.nnn;
  isDarwin = pkgs.stdenv.isDarwin;
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

    _custom.hm = {
      programs.nnn = {
        enable = true;
        package = pkgs.nnn.override { withNerdIcons = true; };
        extraPackages = with pkgs;
          [
            (writeShellScriptBin "scope.sh" (builtins.readFile
              "${pkgs.ranger}/share/doc/ranger/config/scope.sh"))
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
          src = "${pkgs.nnn}/share/plugins";
        };
      };
    };
  };
}
