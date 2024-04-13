{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.programs.tmux;
  inherit (config._custom.globals) configDirectory themeColors;
in {
  options._custom.programs.tmux = {
    enable = lib.mkEnableOption { };
    systemdEnable = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ tmux tmuxp ];

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
          Environment = [ "TERM=alacritty" ];
          PassEnvironment = [ "PATH" "DISPLAY" "HOME" ];
          ExecStart = "${pkgs.tmux}/bin/tmux new-session -d";
          ExecStop = [
            "${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/scripts/save.sh"
            "${pkgs.tmux}/bin/tmux kill-server"
          ];
          KillMode = "mixed";
          RestartSec = 2;
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
  };
}
