{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.programs.tmux;
  inherit (config._custom.globals) configDirectory themeColors;

  kill-unnamed-tmux-sessions = pkgs.writeScriptBin "kill-unnamed-tmux-sessions"
    (builtins.readFile ./scripts/kill-unnamed-tmux-sessions.sh);
  start-tmux-server = pkgs.writeScriptBin "start-tmux-server" ''
    #!/usr/bin/env bash

    ${pkgs.tmux}/bin/tmux kill-server
    TMUX_ID=$(${pkgs.tmux}/bin/tmux new-session -d -P)
    ${pkgs.tmux}/bin/tmux kill-session -t tmux-server
    ${pkgs.tmux}/bin/tmux rename-session -t $TMUX_ID tmux-server
    ${kill-unnamed-tmux-sessions}/bin/kill-unnamed-tmux-sessions
  '';
  stop-tmux-server = pkgs.writeScriptBin "stop-tmux-server" ''
    #!/usr/bin/env bash

    ${kill-unnamed-tmux-sessions}/bin/kill-unnamed-tmux-sessions
    ${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/scripts/save.sh
    ${pkgs.tmux}/bin/tmux kill-server
  '';
in {
  options._custom.programs.tmux = {
    enable = lib.mkEnableOption { };
    systemdEnable = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      kill-unnamed-tmux-sessions
      tmux
      tmuxp
    ];

    _custom.hm = {
      xdg.configFile = {
        "tmux/plugins/sensible".source =
          "${pkgs.tmuxPlugins.sensible}/share/tmux-plugins/sensible";
        "tmux/plugins/yank".source =
          "${pkgs.tmuxPlugins.yank}/share/tmux-plugins/yank";
        "tmux/plugins/resurrect".source =
          "${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect";
        "tmux/plugins/continuum".source =
          "${pkgs.tmuxPlugins.continuum}/share/tmux-plugins/continuum";
        "tmux/plugins/catppuccin".source = inputs.catppuccin-tmux;
        "tmux/tmux.conf".text = ''
          set -g @catppuccin_flavour '${themeColors.flavor}'
          source-file $HOME/.config/tmux/config.conf
        '';
        "tmux/config.conf".source =
          lib._custom.relativeSymlink configDirectory ./dotfiles/config.conf;
      };

      programs.fzf.tmux.enableShellIntegration = true;

      # systemd service required by tmux-continuum
      systemd.user.services.tmux-server = lib.mkIf cfg.systemdEnable {
        Unit = {
          Description = "tmux default session (detached)";
          Documentation = "man:tmux(1)";
        };
        Service = {
          Type = "forking";
          Environment = [ "TERM=foot" ];
          PassEnvironment = [ "PATH" "DISPLAY" "HOME" ];
          ExecStart = "${start-tmux-server}/bin/start-tmux-server";
          ExecStop = "${stop-tmux-server}/bin/stop-tmux-server";
          KillMode = "mixed";
          RestartSec = 2;
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
  };
}
