{ config, pkgs, lib, inputs, _customLib, ... }:

let
  cfg = config._custom.gui.kitty;
  isDarwin = config._displayServer == "darwin";
  macosConfig = builtins.readFile ./dotfiles/kitty-macos.conf;
  linuxConfig = builtins.readFile ./dotfiles/kitty-linux.conf;
  inherit (config._custom.globals) themeColors;
  userName = config._userName;
  relativeSymlink = path:
    config.home-manager.users.${userName}.lib.file.mkOutOfStoreSymlink
    (_customLib.runtimePath config._custom.globals.configDirectory path);

  shellIntegrationInit = {
    bash = ''
      if test -n "$KITTY_INSTALLATION_DIR"; then
        source "$KITTY_INSTALLATION_DIR/shell-integration/bash/kitty.bash"
      fi
    '';
    zsh = ''
      if test -n "$KITTY_INSTALLATION_DIR"; then
        autoload -Uz -- "$KITTY_INSTALLATION_DIR"/shell-integration/zsh/kitty-integration
        kitty-integration
        unfunction kitty-integration
      fi
    '';
  };
in {
  options._custom.gui.kitty = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    environment = {
      etc = {
        "config/kitty-session-tripper.conf".source =
          ./dotfiles/kitty-session-tripper.conf;
        "config/kitty-session-booker.conf".source =
          ./dotfiles/kitty-session-booker.conf;
        "config/kitty-session-cinefest.conf".source =
          ./dotfiles/kitty-session-cinefest.conf;
        "config/kitty-session-nix-config.conf".source =
          ./dotfiles/kitty-session-nix-config.conf;
      };
    };

    home-manager.users.${userName} = {
      home = {
        packages = with pkgs;
          [
            prevstable-kitty.kitty # terminal
          ];

        sessionVariables = lib.mkMerge [
          {
            # TODO: test on darwin ⬇
            TERMINAL = "kitty";
          }
          (lib.mkIf isDarwin {
            # TERM = "xterm-kitty";
            TERMINFO_DIRS =
              "${pkgs.kitty.terminfo.outPath}/share/terminfo:$TERMINFO_DIRS";
          })
        ];

        shellAliases = {
          diff = "kitty +kitten diff";
          gdiff = "git difftool --no-symlinks --dir-diff";
          icat = "kitty +kitten icat";
          # https://sw.kovidgoyal.net/kitty/faq/#i-get-errors-about-the-terminal-being-unknown-or-opening-the-terminal-failing-when-sshing-into-a-different-computer
          sshk = "kitty +kitten ssh";
        };
      };

      # manually add kitty shell integration
      programs.bash.initExtra = shellIntegrationInit.bash;
      programs.zsh.initExtra = shellIntegrationInit.zsh;

      xdg.configFile = {
        "kitty/diff.conf".text = ''
          # Load theme
          include ${inputs.catppuccin-kitty}/themes/diff-late.conf

          ${builtins.readFile ./dotfiles/kitty-diff.conf}
        '';
        "kitty/common.conf".source =
          relativeSymlink ./dotfiles/kitty-common.conf;
        "kitty/kitty.conf".text = ''
          # Load theme
          include ${inputs.catppuccin-kitty}/themes/mocha.conf

          # Load config
          include ./common.conf
          ${if isDarwin then macosConfig else linuxConfig}

          # Theme
          active_border_color ${themeColors.primary}
          inactive_border_color ${themeColors.selection}
        '';
        "kitty/open-actions.conf".source = ./dotfiles/open-actions.conf;
        "kitty/mime.types".source = ./dotfiles/mime.types;

        "kitty/scripts/kitty-top.sh" = {
          source = ./scripts/kitty-top.sh;
          recursive = true;
          executable = true;
        };
        "kitty/scripts/kitty-newsboat.sh" = {
          source = ./scripts/kitty-newsboat.sh;
          recursive = true;
          executable = true;
        };
        "kitty/scripts/kitty-neomutt.sh" = {
          source = ./scripts/kitty-neomutt.sh;
          recursive = true;
          executable = true;
        };
        "kitty/scripts/kitty-neorg.sh" = {
          source = ./scripts/kitty-neorg.sh;
          recursive = true;
          executable = true;
        };
        "kitty/scripts/kitty-nmtui.sh" = {
          source = ./scripts/kitty-nmtui.sh;
          recursive = true;
          executable = true;
        };
        "kitty/scripts/kitty-scratch.sh" = {
          source = ./scripts/kitty-scratch.sh;
          recursive = true;
          executable = true;
        };
        "kitty/scripts/kitty-ncmpcpp.sh" = {
          source = ./scripts/kitty-ncmpcpp.sh;
          recursive = true;
          executable = true;
        };
        "kitty/scripts/kitty-buku.sh" = {
          source = ./scripts/kitty-buku.sh;
          recursive = true;
          executable = true;
        };

        # kittens
        "kitty/custom_pass_keys.py" = {
          source = ./dotfiles/custom_pass_keys.py;
          executable = true;
        };
        "kitty/pass_keys.py" = {
          source = "${inputs.smart-splits-nvim}/kitty/pass_keys.py";
          executable = true;
        };
        "kitty/neighboring_window.py" = {
          source = "${inputs.smart-splits-nvim}/kitty/neighboring_window.py";
          executable = true;
        };
        "kitty/relative_resize.py" = {
          source = "${inputs.smart-splits-nvim}/kitty/relative_resize.py";
          executable = true;
        };
        "kitty/kitty_scrollback_nvim.py" = {
          source =
            "${inputs.kitty-scrollback-nvim}/python/kitty_scrollback_nvim.py";
          executable = true;
        };
        "kitty/smart_scroll.py" = {
          source = "${inputs.kitty-smart-scroll}/smart_scroll.py";
          executable = true;
        };
        "kitty/smart_tab.py" = {
          source = "${inputs.kitty-smart-tab}/smart_tab.py";
          executable = true;
        };
      };

    };
  };
}
