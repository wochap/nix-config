{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.programs.tmux;
  inherit (config._custom.globals)
    configDirectory themeColorsLight themeColorsDark preferDark userName;
  hmConfig = config.home-manager.users.${userName};

  fzfDefaultOptsStr = lib.strings.concatStringsSep " "
    (hmConfig.programs.fzf.defaultOptions ++ [
      # remove border added by fzf-tmux
      "--border 'none'"
      "--padding '0,1'"
    ]);

  mkThemeTmux = themeColors: ''
    set -g popup-border-style "bg=default,fg=${themeColors.primary}"
    set -g @catppuccin_flavour "${themeColors.flavour}"
    set -g @catppuccin_pane_active_border_style "fg=${themeColors.primary}"
    set -g @catppuccin_pane_border_style "fg=${themeColors.border}"
    set -g @catppuccin_status_default "off"
    set -g @catppuccin_status_background 'default'

    set -g pane-border-lines single
    set -g popup-border-lines rounded
    set -g status off

    run-shell ~/.config/tmux/plugins/catppuccin/catppuccin.tmux
    run-shell ~/.config/tmux/plugins/status-bar/status-bar.tmux
  '';
  catppuccin-tmux-light-theme = mkThemeTmux themeColorsLight;
  catppuccin-tmux-dark-theme = mkThemeTmux themeColorsDark;
  tmux-final = cfg.package;
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
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.tmux;
    };
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

        # NOTE: fix newline pasting broken in neovim
        # source: https://github.com/tmux/tmux/issues/4163
        tmux = prev.tmux.overrideAttrs (oldAttrs: rec {
          version = "b13005e802df23652e87c98f136f9eb13f096374";
          src = pkgs.fetchFromGitHub {
            owner = "tmux";
            repo = "tmux";
            rev = version;
            hash = "sha256-V/F16gXadfSoR7kdq5pKXdL7nnqjYuZQl+P8DIZTcGM=";
          };
        });
      })
    ];

    environment.systemPackages = with pkgs; [
      tmux-final
      tmux-kill-unattached-sessions
      tmux-kill-unnamed-sessions
      _custom.tmuxinator # session manager
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
        "tmux/tmux-light.conf".text = catppuccin-tmux-light-theme;
        "tmux/tmux-dark.conf".text = catppuccin-tmux-dark-theme;
        "tmux/tmux.conf".text = ''
          set -gu default-command
          set -g default-shell ${pkgs.zsh}/bin/zsh
          ${if preferDark then
            catppuccin-tmux-dark-theme
          else
            catppuccin-tmux-light-theme}
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
