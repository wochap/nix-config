{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.programs.git;
  inherit (config._custom.globals) themeColorsLight themeColorsDark;
  git-final = pkgs.gitAndTools.gitFull;
in {
  options._custom.programs.git = {
    enable = lib.mkEnableOption { };
    enableUser = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ git-final ];

    # TODO: wait for https://github.com/dandavison/delta/issues/1976
    _custom.programs.rod.config = {
      # TODO: cmds.delta.light.env didn't work
      light.env = {
        DELTA_FEATURES = "+catppuccin-${themeColorsLight.flavour}";
      };
      dark.env = { DELTA_FEATURES = "+catppuccin-${themeColorsDark.flavour}"; };
    };

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

      programs.zsh.initContent =
        lib.mkOrder 1000 (builtins.readFile ./dotfiles/git.zsh);

      programs.gh = {
        enable = true;
        extensions = [ pkgs._custom.gh-prx ];
      };

      programs.gh-dash = { enable = true; };

      programs.git = {
        package = git-final;
        enable = true;

        ignores = [ ".direnv" ".envrc" ".cache" ".aider*" ];

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
