{ config, pkgs, inputs, ... }:

let
  userName = config._userName;
  catppuccinMochaTheme =
    pkgs._custom.fromYAML "${inputs.catppuccin-lazygit}/themes/mocha.yml";
in {
  config = {
    nixpkgs.overlays = [
      (final: prev: {
        lazygit = prev.lazygit.overrideAttrs (_: {
          src = prev.fetchFromGitHub {
            owner = "jesseduffield";
            repo = "lazygit";
            rev = "e60936e964e0b978532745f319fc4600c00de7d7";
            sha256 = "sha256-fP12JfOyeXdQXUur2PToV29PIXc9bT3J/xJr75BOC0o=";
          };
        });
      })
    ];

    environment = {
      shellAliases = {
        gs = "git status";
        gc = "git clone";
        glo = "git pull origin";
        gpo = "git push origin";
        lg = "lazygit";
      };
    };

    home-manager.users.${userName} = {
      home.packages = with pkgs; [ commitizen ];

      programs.lazygit = {
        enable = true;
        package = pkgs.unstable.lazygit;
        settings = {
          os = {
            open = "xdg-open {{filename}} >/dev/null";
            edit =
              "nvr -cc split --remote-wait +'set bufhidden=wipe' {{filename}}";
            # TODO: add editAtLine
            suspend = true;
          };
          gui = {
            showFileTree = false;
            scrollHeight = 10;
            inherit (catppuccinMochaTheme) theme;
          };
          git.paging = {
            colorArg = "always";
            pager = "delta --paging=never";
          };
        };
      };

      # TODO: setup gh signature verification
      programs.git = {
        package = pkgs.gitAndTools.gitFull;
        enable = true;

        ignores = [ ".direnv" ".vscode" ".envrc" ];

        aliases = {
          co = "checkout";
          ci = "commit";
          st = "status";
        };

        delta = {
          enable = true;
          options = {
            features = "side-by-side line-numbers decorations";
            navigate = true;

            # available themes `delta --list-syntax-themes`
            syntax-theme = "Catppuccin-mocha";

            file-modified-label = "modified:";
            decorations = { commit-decoration-style = "yellow box ul"; };
            line-numbers = {
              line-numbers-minus-style = "124";
              line-numbers-plus-style = "28";
            };
          };
        };

        extraConfig = {
          diff = { colorMoved = "default"; };
          color.ui = "auto";
          pull.rebase = "false";
          init = { defaultBranch = "main"; };
          merge = { conflictstyle = "diff3"; };

          user = {
            email = "gean.marroquin@gmail.com";
            name = "wochap";
            signingKey = "gean.marroquin@gmail.com";
          };
          commit = { gpgSign = true; };
        };
        includes = [{
          condition = "gitdir:~/Projects/boc/**/.git";
          contents = {
            user = {
              email = "geanb@bandofcoders.com";
              name = "Gean";
              signingKey = "geanb@bandofcoders.com";
            };
            commit = { gpgSign = true; };
          };
        }];

      };
    };
  };
}
