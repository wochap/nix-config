{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.programs.git;
  inherit (config._custom.globals) themeColorsLight themeColorsDark secrets configDirectory;
  inherit (lib._custom) relativeSymlink;
  git-final = pkgs.gitFull;
  wt = pkgs.writeScriptBin "wt" (builtins.readFile ./scripts/wt.sh);
in
{
  options._custom.programs.git = {
    enable = lib.mkEnableOption { };
    enableUser = lib.mkEnableOption { };
    enableSandboxUser = lib.mkEnableOption { };
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
        gh # github cli
        gitflow
        gut # alternative git cli
        wt
      ];

      programs.bash.initExtra = lib.mkOrder 1000 (builtins.readFile ./scripts/wt.plugin.sh);
      programs.zsh.initContent =
        lib.mkOrder 1000 ''
          source ${relativeSymlink configDirectory ./dotfiles/git.zsh}

          # TODO: wait for https://github.com/dandavison/delta/issues/1976
          _apply_delta_theme() {
            if [[ "$1" == "dark" ]]; then
                export DELTA_FEATURES="+catppuccin-${themeColorsDark.flavour}"
            else
                export DELTA_FEATURES="+catppuccin-${themeColorsLight.flavour}"
            fi
          }
          add-theme-hook _apply_delta_theme
          _apply_delta_theme $CURRENT_SCHEME

          source ${./scripts/wt.plugin.sh}
          zsh-defer source ${./scripts/wt.completions.zsh}
        '';

      programs.gh = {
        enable = true;
        extensions = [ pkgs._custom.gh-prx ];
      };

      programs.gh-dash = { enable = true; };

      programs.git = {
        package = git-final;
        enable = true;

        ignores = [ ".direnv" ".envrc" ".cache" ".aider*" ".claude" ];

        # enable Git Large File Storage
        lfs = {
          enable = true;
          skipSmudge = true;
        };

        settings = {
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
        } // lib.optionalAttrs cfg.enableSandboxUser {
          user = {
            email = "sandbox@localhost";
            name = "sandbox";
          };
        };

        includes =
          [{ path = "${inputs.catppuccin-delta}/catppuccin.gitconfig"; }]
          ++ lib.optionals cfg.enableUser [
            {
              condition = "gitdir:~/Projects/boc/**/.git";
              contents = {
                user = {
                  email = secrets.boc.email;
                  name = "Gean";
                  signingKey = secrets.boc.email;
                };
                commit.gpgSign = true;
              };
            }
            {
              condition = "gitdir:~/Projects/se/**/.git";
              contents = {
                user = {
                  email = secrets.se.email;
                  name = "Gean";
                  signingKey = secrets.se.email;
                };
                commit.gpgSign = true;
              };
            }
          ];
      };

      programs.delta = {
        enable = true;
        enableGitIntegration = true;
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
    };
  };
}
