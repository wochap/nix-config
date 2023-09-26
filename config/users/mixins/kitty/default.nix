{ config, pkgs, lib, inputs, ... }:

let
  isDarwin = config._displayServer == "darwin";
  macosConfig = builtins.readFile ./dotfiles/kitty-macos.conf;
  linuxConfig = builtins.readFile ./dotfiles/kitty-linux.conf;
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  inherit (hmConfig.lib.file) mkOutOfStoreSymlink;
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
          (lib.mkIf isDarwin {
            # TERM = "xterm-kitty";
            TERMINFO_DIRS =
              "${pkgs.kitty.terminfo.outPath}/share/terminfo:$TERMINFO_DIRS";
          })
        ];

        shellAliases = {
          icat = "kitty +kitten icat";

          # https://sw.kovidgoyal.net/kitty/faq/#i-get-errors-about-the-terminal-being-unknown-or-opening-the-terminal-failing-when-sshing-into-a-different-computer
          sshk = "kitty +kitten ssh";
        };
      };

      xdg.configFile = {
        "kitty/common.conf".source =
          mkOutOfStoreSymlink "${currentDirectory}/dotfiles/kitty-common.conf";
        "kitty/kitty.conf".text = ''
          # Load theme
          include ${inputs.catppuccin-kitty}/themes/diff-mocha.conf
          include ${inputs.catppuccin-kitty}/themes/mocha.conf

          # Load config
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
      };

    };
  };
}
