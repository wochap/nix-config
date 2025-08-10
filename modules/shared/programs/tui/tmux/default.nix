{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.programs.tmux;
  inherit (config._custom.globals) configDirectory themeColors userName;
  hmConfig = config.home-manager.users.${userName};

  fzfDefaultOptsStr = lib.strings.concatStringsSep " "
    (hmConfig.programs.fzf.defaultOptions ++ [
      # remove border added by fzf-tmux
      "--border 'none'"
      "--padding '0,1'"
    ]);

  # NOTE: tmux v3.5a introduced a change that broke keybindings using the Shift key
  tmux-final = pkgs.nixpkgs-24-05.tmux; # tmux v3.4
  tmux-sessionx =
    inputs.tmux-sessionx.packages.${pkgs.system}.default.overrideAttrs
    (oldAttrs: { postInstall = ""; });
  tmux-kill-unnamed-sessions = pkgs.writeScriptBin "tmux-kill-unnamed-sessions"
    (builtins.readFile ./scripts/tmux-kill-unnamed-sessions.sh);
  tmux-kill-unattached-sessions =
    pkgs.writeScriptBin "tmux-kill-unattached-sessions"
    (builtins.readFile ./scripts/tmux-kill-unattached-sessions.sh);
  start-tmux-server = pkgs.writeScriptBin "start-tmux-server" ''
    #!/usr/bin/env bash

    ${tmux-final}/bin/tmux -L default kill-server
    TMUX_ID=$(${tmux-final}/bin/tmux new-session -d -P)
    ${tmux-final}/bin/tmux kill-session -t tmux-server
    ${tmux-final}/bin/tmux rename-session -t $TMUX_ID tmux-server
    # ${tmux-kill-unnamed-sessions}/bin/tmux-kill-unnamed-sessions
    # ${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/scripts/save.sh
  '';
  stop-tmux-server = pkgs.writeScriptBin "stop-tmux-server" ''
    #!/usr/bin/env bash

    # ${tmux-kill-unnamed-sessions}/bin/tmux-kill-unnamed-sessions
    # ${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/scripts/save.sh
    ${tmux-final}/bin/tmux -L default kill-server
  '';
in {
  options._custom.programs.tmux = {
    enable = lib.mkEnableOption { };
    systemdEnable = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        # HACK: don't remove popup border
        fzf = prev.fzf.overrideAttrs (oldAttrs: rec {
          postPatch = ''
            ${oldAttrs.postPatch}
            substituteInPlace bin/fzf-tmux \
              --replace "opt=\"-B" "# opt=\"-B"
          '';
        });
      })
    ];

    environment.systemPackages = with pkgs; [
      tmux-final
      tmux-kill-unattached-sessions
      tmux-kill-unnamed-sessions
      tmuxinator # session manager
      tmuxp # session manager
    ];

    _custom.hm = {
      xdg.configFile = {
        "tmuxinator".source =
          lib._custom.relativeSymlink configDirectory ./dotfiles/tmuxinator;
        "tmux/plugins/sensible".source =
          "${pkgs.tmuxPlugins.sensible}/share/tmux-plugins/sensible";
        "tmux/plugins/yank".source =
          "${pkgs.tmuxPlugins.yank}/share/tmux-plugins/yank";
        "tmux/plugins/resurrect".source =
          "${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect";
        "tmux/plugins/continuum".source =
          "${pkgs.tmuxPlugins.continuum}/share/tmux-plugins/continuum";
        "tmux/plugins/tmux-sessionx".source =
          "${tmux-sessionx}/share/tmux-plugins/sessionx";
        "tmux/plugins/catppuccin".source = inputs.catppuccin-tmux;
        "tmux/tmux.conf".text = ''
          set -g default-shell ${pkgs.zsh}/bin/zsh
          set -g popup-border-style "bg=default,fg=${themeColors.primary}"
          set -g @catppuccin_flavour "${themeColors.flavour}"
          set -g @catppuccin_pane_active_border_style "fg=${themeColors.primary}"
          set -g @catppuccin_pane_border_style "fg=${themeColors.border}"
          source-file $HOME/.config/tmux/config.conf
        '';
        "tmux/config.conf".source =
          lib._custom.relativeSymlink configDirectory ./dotfiles/config.conf;
        "tmux/plugins/status-bar/status-bar.tmux".source =
          lib._custom.relativeSymlink configDirectory
          ./dotfiles/status-bar.tmux;
      };

      programs.fzf.tmux.enableShellIntegration = true;

      # systemd service required by tmux-continuum
      systemd.user.services.tmux-server = lib.mkIf cfg.systemdEnable {
        Unit = {
          Description = "tmux default session (detached)";
          Documentation = "man:tmux(1)";
          PartOf = "graphical-session.target";
          After = "graphical-session.target";
          ConditionEnvironment = "WAYLAND_DISPLAY";
        };
        Service = {
          Type = "forking";
          Environment = [
            # NOTE: when starting tmux from systemctl and not from a terminal
            # the following env variables are empty
            # I only plan to use tmux within foot
            "TERM=foot"
            "TERMINFO=${pkgs.foot.terminfo}/share/terminfo" # required by my zsh keybindings
            "COLORTERM=truecolor" # required by bat

            # tmux-server service doesn't inherit FZF_DEFAULT_OPTS env var
            ''FZF_DEFAULT_OPTS="${fzfDefaultOptsStr}"''
          ];
          ExecStart = "${start-tmux-server}/bin/start-tmux-server";
          ExecStop = "${stop-tmux-server}/bin/stop-tmux-server";
          KillMode = "mixed";
          RestartSec = 2;
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
