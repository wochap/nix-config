{
  config,
  lib,
  inputs,
  ...
}:

let
  cfg = config._custom.programs.lazygit;
  inherit (config._custom.globals) themeColorsLight themeColorsDark;
in
{
  options._custom.programs.lazygit.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      xdg.configFile = {
        "lazygit/config-${themeColorsLight.flavour}.yml".source =
          "${inputs.catppuccin-lazygit}/themes-mergable/${themeColorsLight.flavour}/mauve.yml";
        "lazygit/config-${themeColorsDark.flavour}.yml".source =
          "${inputs.catppuccin-lazygit}/themes-mergable/${themeColorsDark.flavour}/mauve.yml";
      };

      programs.zsh = {
        shellAliases = {
          lg = ''run-without-kpadding lazygit "$@"'';
        };

        # TODO: wait for https://github.com/jesseduffield/lazygit/issues/4366
        initContent = lib.mkOrder 1000 ''
          _apply_lazygit_theme() {
            if [[ "$1" == "dark" ]]; then
                export LG_CONFIG_FILE="$HOME/.config/lazygit/config.yml,$HOME/.config/lazygit/config-${themeColorsDark.flavour}.yml"
            else
                export LG_CONFIG_FILE="$HOME/.config/lazygit/config.yml,$HOME/.config/lazygit/config-${themeColorsLight.flavour}.yml"
            fi
          }
          add-theme-hook _apply_lazygit_theme
          _apply_lazygit_theme $CURRENT_SCHEME
        '';
      };

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
            useHunkModeInStagingView = false;
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
            autoFetch = false;
            overrideGpg = true;
            pagers = [
              {
                colorArg = "always";
                pager = ''delta --detect-dark-light=always --paging=never --line-numbers --hyperlinks --hyperlinks-file-link-format="lazygit-edit://{path}:{line}"'';
              }
            ];
          };
          keybinding = {
            universal = {
              prevPage = "<c-b>";
              nextPage = "<c-f>";
              gotoTop = "g";
              gotoBottom = "G";
            };
            commits = {
              viewResetOptions = "E";
            };
            stash = {
              popStash = "<space>";
            };
          };
        };
      };
    };
  };
}
