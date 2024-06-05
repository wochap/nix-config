{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.programs.git;
  inherit (config._custom.globals) themeColors;
  catppuccinTheme = lib._custom.fromYAML
    "${inputs.catppuccin-lazygit}/themes/${themeColors.flavor}/mauve.yml";
  git-final = pkgs.gitAndTools.gitFull;
in {
  options._custom.programs.git = {
    enable = lib.mkEnableOption { };
    enableUser = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        lazygit = prev.lazygit.overrideAttrs (_: rec {
          version = "v0.41.0";
          src = prev.fetchFromGitHub {
            owner = "jesseduffield";
            repo = "lazygit";
            rev = version;
            sha256 = "sha256-Ok6QnXw3oDeSzBekft8cDXM/YsADgF1NZznfNoGNvck=";
          };
        });
      })
    ];

    environment.systemPackages = [ git-final ];

    _custom.hm = {
      home.shellAliases = {
        gst = "git status";
        gc = "git clone";
        gco = "git checkout";
        gcmsg = "git commit --message";
      };

      home.packages = with pkgs; [
        commitizen
        git-town
        gitAndTools.gh # github cli
        gitflow
      ];

      programs.zsh.shellAliases = {
        lg = ''run-without-kpadding lazygit "$@"'';
      };

      programs.lazygit = {
        enable = true;
        settings = {
          update.method = "never";
          disableStartupPopups = true;
          os = {
            open = "xdg-open {{filename}} >/dev/null";
            editPreset = "nvim-remote";
            edit = "nvr -l --remote-silent +':WindowPicker {{filename}}'";
            editAtLine =
              "nvr -l --remote-silent +':WindowPicker {{filename}}' +':{{line}}'";
            editAtLineAndWaitTemplate =
              "nvr -l --remote-wait-silent +':WindowPicker {{filename}}' +':{{line}}'";
          };
          gui = {
            theme = {
              inherit (catppuccinTheme.theme)
                optionsTextColor selectedLineBgColor cherryPickedCommitBgColor
                cherryPickedCommitFgColor unstagedChangesColor defaultFgColor
                searchingActiveBorderColor;
              activeBorderColor = [ themeColors.mauve ];
              inactiveBorderColor = [ themeColors.textDimmed ];
            };
            showBottomLine = false;
            showPanelJumps = false;
            filterMode = "fuzzy";
            border = "rounded";
            mainPanelSplitMode = "vertical";
            nerdFontsVersion = "3";
            scrollHeight = 10;
            scrollOffMargin = 4;
            showFileTree = false;
            sidePanelWidth = 0.3333;
          };
          git.paging = {
            colorArg = "always";
            pager = "delta --dark --paging=never";
          };
        };
      };

      programs.git = {
        package = git-final;
        enable = true;

        ignores =
          [ ".direnv" ".vscode" ".envrc" ".cache" "compile_commands.json" ];

        delta = {
          enable = true;
          options = {
            features = "side-by-side line-numbers decorations";
            navigate = true;

            # available themes `delta --list-syntax-themes`
            syntax-theme = "Catppuccin-${themeColors.flavor}";

            file-modified-label = "modified:";
            decorations.commit-decoration-style = "yellow box ul";
            line-numbers = {
              line-numbers-minus-style = "124";
              line-numbers-plus-style = "28";
            };
          };
        };

        extraConfig = lib.mkMerge [
          {
            core.editor = "nvr -l --remote-silent -O";
            diff = {
              tool = "kitty";
              guitool = "kitty.gui";
              colorMoved = "default";
            };
            difftool = {
              prompt = "false";
              trustExitCode = "true";
              kitty = { cmd = "kitty +kitten diff $LOCAL $REMOTE"; };
              "kitty.gui" = {
                cmd = "kitty kitty +kitten diff $LOCAL $REMOTE";
              };
            };
            color.ui = "auto";
            pull.rebase = "false";
            init = { defaultBranch = "main"; };
            merge = { conflictstyle = "diff3"; };
          }

          (lib.mkIf cfg.enableUser {
            user = {
              email = "gean.marroquin@gmail.com";
              name = "wochap";
              signingKey = "gean.marroquin@gmail.com";
            };
            commit.gpgSign = true;
          })
        ];
        includes = [
          { path = "${inputs.catppuccin-delta}/catppuccin.gitconfig"; }

          (lib.mkIf cfg.enableUser {
            condition = "gitdir:~/Projects/boc/**/.git";
            contents = {
              user = {
                email = "geanb@bandofcoders.com";
                name = "Gean";
                signingKey = "geanb@bandofcoders.com";
              };
              commit.gpgSign = true;
            };
          })

          (lib.mkIf cfg.enableUser {
            condition = "gitdir:~/Projects/se/**/.git";
            contents = {
              user = {
                email = "gean.bonifacio@socialexplorer.com";
                name = "Gean";
                signingKey = "gean.bonifacio@socialexplorer.com";
              };
              commit.gpgSign = true;
            };
          })
        ];
      };
    };
  };
}
