{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  cfg = config._custom.programs.tmux;
  inherit (config._custom.globals)
    configDirectory
    systemdTarget
    ;

  fzfDefaultOptsStr = lib.strings.concatStringsSep " " (
    config._custom.programs.fzf.defaultOptions
    ++ [
      # remove border added by fzf-tmux
      "--border 'none'"
      "--padding '0,1'"
    ]
  );

  tmux-final = cfg.package;
  tmux-kill-unnamed-sessions = pkgs.writeScriptBin "tmux-kill-unnamed-sessions" (
    builtins.readFile ./scripts/tmux-kill-unnamed-sessions.sh
  );
  tmux-kill-unattached-sessions = pkgs.writeScriptBin "tmux-kill-unattached-sessions" (
    builtins.readFile ./scripts/tmux-kill-unattached-sessions.sh
  );
  tmux-fzf-panes = pkgs.writeScriptBin "tmux-fzf-panes" (
    builtins.readFile ./scripts/tmux-fzf-panes.sh
  );
  tmux-fzf-sessions = pkgs.writeScriptBin "tmux-fzf-sessions" (
    builtins.readFile ./scripts/tmux-fzf-sessions.sh
  );
  tmux-accordion = pkgs.writeScriptBin "tmux-accordion" (
    builtins.readFile ./scripts/tmux-accordion.sh
  );
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
in
{
  options._custom.programs.tmux = {
    enable = lib.mkEnableOption { };
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.tmux.overrideAttrs (oldAttrs: rec {
        # PERF: 3.7 give performance issues on nvim and in general
        version = "3.6b";
        src = pkgs.fetchFromGitHub {
          owner = "tmux";
          repo = "tmux";
          tag = version;
          hash = "sha256-iW4K/OxSVpxVkyI5Dy6lzwVf/8nXyjcHtL76Ezmxavc=";
        };
        patches = (oldAttrs.patches or [ ]) ++ [ ./patches/tmux-osc777.patch ];
      });
    };
    enableSystemd = lib.mkEnableOption { };
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
      tmux-accordion
      tmux-fzf-panes
      tmux-fzf-sessions
      tmux-final
      tmux-kill-unattached-sessions
      tmux-kill-unnamed-sessions
      _custom.tmuxinator # session manager
      tmuxp # session manager
    ];

    _custom.hm = {
      xdg.configFile = {
        "tmuxinator".source = lib._custom.relativeSymlink configDirectory ./dotfiles/tmuxinator;
        "tmux/plugins/sensible".source = "${pkgs.tmuxPlugins.sensible}/share/tmux-plugins/sensible";
        "tmux/plugins/yank".source = "${pkgs.tmuxPlugins.yank}/share/tmux-plugins/yank";
        "tmux/plugins/resurrect".source = "${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect";
        "tmux/plugins/continuum".source = "${pkgs.tmuxPlugins.continuum}/share/tmux-plugins/continuum";
        "tmux/tmux.conf".text = ''
          set -gu default-command
          set -g default-shell ${pkgs.zsh}/bin/zsh

          run-shell ~/.config/tmux/plugins/custom-theme/custom-theme.tmux
          source-file $HOME/.config/tmux/config.conf
        '';
        "tmux/config.conf".source = lib._custom.relativeSymlink configDirectory ./dotfiles/config.conf;
        "tmux/plugins/custom-theme/custom-theme.tmux".source =
          lib._custom.relativeSymlink configDirectory ./dotfiles/custom-theme.tmux;
      };

      programs.zsh.initContent = lib.mkOrder 1000 (builtins.readFile ./dotfiles/tmux.zsh);

      programs.fzf.tmux.enableShellIntegration = false;

      # systemd service required by tmux-continuum
      systemd.user.services.tmux-server = lib.mkIf cfg.enableSystemd {
        Unit = {
          Description = "tmux default session (detached)";
          Documentation = "man:tmux(1)";
          PartOf = systemdTarget;
          After = systemdTarget;
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
        Install.WantedBy = [ systemdTarget ];
      };
    };
  };
}
