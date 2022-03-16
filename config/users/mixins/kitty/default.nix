{ config, pkgs, lib, inputs, ... }:

let
  isDarwin = config._displayServer == "darwin";
  macosConfig = builtins.readFile ./dotfiles/kitty-macos.conf;
  linuxConfig = builtins.readFile ./dotfiles/kitty-linux.conf;
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  mkOutOfStoreSymlink = hmConfig.lib.file.mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory = "${configDirectory}/config/users/mixins/kitty";
in {
  config = {
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
            kitty # terminal
          ];

        sessionVariables = lib.mkMerge [
          {
            # TODO: test on darwin ⬇
            TERMINAL = "kitty";
          }
          (lib.mkIf (isDarwin) {
            # TERM = "xterm-kitty";
            TERMINFO_DIRS =
              "${pkgs.kitty.terminfo.outPath}/share/terminfo:$TERMINFO_DIRS";
          })
        ];

        shellAliases = {
          TERMINAL = "kitty";

          icat = "kitty +kitten icat";

          # https://sw.kovidgoyal.net/kitty/faq/#i-get-errors-about-the-terminal-being-unknown-or-opening-the-terminal-failing-when-sshing-into-a-different-computer
          sshk = "kitty +kitten ssh";
        };
      };

      xdg.configFile = {
        "kitty/tab_bar.py".source = ./scripts/tab_bar.py;
        "kitty/open-actions.conf".source = ./dotfiles/open-actions.conf;
        "kitty/diff.conf".source = "${inputs.dracula-kitty}/diff.conf";
        "kitty/dracula.conf".source = "${inputs.dracula-kitty}/dracula.conf";
        "kitty/common.conf".source =
          mkOutOfStoreSymlink "${currentDirectory}/dotfiles/kitty-common.conf";
        "kitty/kitty.conf".text = ''
          include ./dracula.conf
          include ./common.conf
          ${if isDarwin then macosConfig else linuxConfig}
        '';

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
      };

      programs.fzf = {
        enable = true;
        enableBashIntegration = true;
      };

      programs.starship = {
        enable = true;
        settings = {
          add_newline = false;
          # character = {
          #   success_symbol = "[➜](bold green)";
          #   error_symbol = "[➜](bold red)";
          # };
          nix_shell = { disabled = true; };
          package = { disabled = true; };

          # Dracula theme
          aws.style = "bold #ffb86c";
          cmd_duration.style = "bold #f1fa8c";
          directory.style = "bold #50fa7b";
          hostname.style = "bold #ff5555";
          git_branch.style = "bold #ff79c6";
          git_status.style = "bold #ff5555";
          username = {
            format = "[$user]($style) on ";
            style_user = "bold #bd93f9";
          };
          character = {
            success_symbol = "[❯](bold #f8f8f2)";
            error_symbol = "[❯](bold #ff5555)";
          };
        };
      };
    };
  };
}
