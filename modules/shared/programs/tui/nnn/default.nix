{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.programs.nnn;
  isDarwin = pkgs.stdenv.isDarwin;
in {
  options._custom.programs.nnn.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.sessionVariables = {
        NNN_OPENER = "${pkgs.nnn}/share/plugins/nuke";
        NNN_SPLIT = "v";
        NNN_TRASH = "1";
      };

      xdg.configFile."nnn/plugins" = {
        source = "${pkgs.nnn}/share/plugins";
        recursive = true;
      };
      xdg.configFile."nnn/plugins/cppath".source =
        "${inputs.nnn-cppath}/cppath";

      programs.nnn = {
        enable = true;
        package = pkgs.nnn.override { withNerdIcons = true; };
        extraPackages = with pkgs;
          [
            # dragdrop dependencies
            xdragon

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
            poppler_utils
            unzip
          ] ++ lib.optionals (!isDarwin) [ ffmpegthumbnailer ];
        plugins = {
          mappings = {
            y = "cppath";
            c = "fzcd";
            f = "finder";
            o = "fzopen";
            p = "preview-tui";
            t = "nmount";
            v = "imgview";
            d = "dragdrop";
          };
          src = null;
        };
      };
      programs.zsh.initContent = builtins.readFile ./dotfiles/f.zsh;
    };
  };
}
