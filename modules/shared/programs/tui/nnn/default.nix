{ config, pkgs, lib, ... }:

let
  cfg = config._custom.programs.nnn;
  isDarwin = pkgs.stdenv.isDarwin;
in {
  options._custom.programs.nnn.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment = {
      variables = {
        NNN_OPENER = "${pkgs.nnn}/share/plugins/nuke";
        NNN_PISTOL = "1";
        NNN_SPLIT = "v";
        NNN_TRASH = "1";
      };
    };

    _custom.hm = {
      programs.nnn = {
        enable = true;
        package = pkgs.nnn.override { withNerdIcons = true; };
        extraPackages = with pkgs;
          [
            # nuke dependencies
            atool # file archives
            rar
            zip
            p7zip
            zathura
            mpv
            glow
            jq
            w3m
            imv

            # preview-tui dependencies
            bat
            eza
            ffmpeg
            fzf
            gnutar
            imagemagick
            mediainfo
            mktemp
            pistol
            poppler_utils
            unzip
          ] ++ lib.optionals (!isDarwin) [ ffmpegthumbnailer ];
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
      programs.zsh.initExtra = builtins.readFile ./dotfiles/f.zsh;
    };
  };
}
