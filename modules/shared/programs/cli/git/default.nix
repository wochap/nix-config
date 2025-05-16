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
    environment.systemPackages = [ git-final ];

    _custom.hm = {
      home.shellAliases = {
        gst = "git status";
        gc = "git clone";
        gco = "git checkout";
        gcmsg = "git commit --message";
        gdiff = "git difftool --no-symlinks --dir-diff";
      };

      home.packages = with pkgs; [
        commitizen
        git-town
        gitAndTools.gh # github cli
        gitflow
        gut # alternative git cli
      ];

      programs.zsh.shellAliases = {
        lg = ''run-without-kpadding lazygit "$@"'';
      };

      programs.zsh.initContent = builtins.readFile ./dotfiles/git.zsh;

      programs.gh = {
        enable = true;
        extensions = [ pkgs._custom.gh-prx ];
      };

      programs.gh-dash = { enable = true; };

      programs.lazygit = {
        enable = true;
        settings = {
          update.method = "never";
          disableStartupPopups = true;
          os = {
            open = # sh
              "xdg-open {{filename}} >/dev/null";
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
            statusPanelView = "allBranchesLog";
            showCommandLog = false; # @ toggles it
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
            expandFocusedSidePanel = true;
          };
          git = {
            overrideGpg = true;
            paging = {
              colorArg = "always";
              pager = ''
                delta --dark --paging=never --line-numbers --hyperlinks --hyperlinks-file-link-format="lazygit-edit://{path}:{line}"'';
            };
          };
        };
      };

      programs.git = {
        package = git-final;
        enable = true;

        ignores = [
          ".direnv"
          ".vscode"
          ".envrc"
          ".cache"
          "compile_commands.json"
          ".aider*"
        ];

        # enable Git Large File Storage
        lfs = {
          enable = true;
          skipSmudge = true;
        };

        delta = {
          enable = true;
          options = {
            features = "side-by-side line-numbers decorations word-diff";
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

        extraConfig = {
          diff = {
            tool = "delta";
            colorMoved = "default";
          };
          # TODO: fix difftool
          difftool = {
            prompt = false;
            trustExitCode = true;
            "delta".cmd = "delta";
          };
          merge = {
            conflictstyle = "diff3";
            tool = "diffview_nvim";
          };
          mergetool = {
            prompt = false;
            keepBackup = false;
            layout = "LOCAL,BASE,REMOTE / MERGED";
            "diffview_nvim".cmd = "nvim -f -n -c 'DiffviewOpen' '$MERGE'";
          };
          color.ui = "auto";
          pull.rebase = false;
          init.defaultBranch = "main";
        } // lib.optionalAttrs cfg.enableUser {
          user = {
            email = "gean.marroquin@gmail.com";
            name = "wochap";
            signingKey = "gean.marroquin@gmail.com";
          };
          commit.gpgSign = true;
        };

        includes =
          [{ path = "${inputs.catppuccin-delta}/catppuccin.gitconfig"; }]
          ++ lib.optionals cfg.enableUser [
            {
              condition = "gitdir:~/Projects/boc/**/.git";
              contents = {
                user = {
                  email = "geanb@bandofcoders.com";
                  name = "Gean";
                  signingKey = "geanb@bandofcoders.com";
                };
                commit.gpgSign = true;
              };
            }
            {
              condition = "gitdir:~/Projects/se/**/.git";
              contents = {
                user = {
                  email = "gean.bonifacio@socialexplorer.com";
                  name = "Gean";
                  signingKey = "gean.bonifacio@socialexplorer.com";
                };
                commit.gpgSign = true;
              };
            }
          ];
      };
    };
  };
}
