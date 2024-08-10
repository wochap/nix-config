{ config, pkgs, lib, ... }:

let
  cfg = config._custom.system.console;
  inherit (config._custom.globals) configDirectory;
  start-tmux = pkgs.writeScriptBin "start-tmux" # bash
    ''
      TERM=fbterm tmux -L fbtmux -f ~/.config/tmux/tmux-fbterm.conf "$@" new -A -s fbtmux
    '';
  start-fbterm = pkgs.writeScriptBin "start-fbterm" # bash
    ''
      TERM=fbterm fbterm -- ${start-tmux}/bin/start-tmux "$@"
    '';
in {
  options._custom.system.console.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      fbcat # screenshoot
      fbida # image and pdf viewer
      fbterm
      fbv # wallpaper, image viewer
      mplayer # video player
      _custom.fcitx5-fbterm

      start-fbterm
    ];

    environment.interactiveShellInit = # bash
      ''
        if [ "$(tty)" = "/dev/tty2" ]; then
          exec ${start-fbterm}/bin/start-fbterm
        fi
      '';

    # fixes unicode not working on a tty
    security.wrappers.fbterm = {
      source = "${pkgs.fbterm}/bin/fbterm";
      owner = "root";
      group = "video";
      capabilities = "cap_sys_tty_config+ep";
    };

    console = {
      earlySetup = true;
      keyMap = lib.mkDefault "us";
      # better TTY font
      font = lib.mkDefault
        "${pkgs.terminus_font}/share/consolefonts/ter-v16n.psf.gz";
    };

    _custom.hm = {
      xdg.configFile = {
        "fbterm/fbtermrc".source =
          lib._custom.relativeSymlink configDirectory ./dotfiles/fbtermrc;
        "tmux/tmux-fbterm.conf".text = ''
          source-file $HOME/.config/tmux/tmux.conf
          set -g default-terminal "screen-256color"
          set -ga terminal-overrides ",screen-256color:Tc"
        '';
      };
    };
  };
}
