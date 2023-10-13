{ config, lib, pkgs, ... }:

let
  cfg = config._custom.neovim;
  isDarwin = config._displayServer == "darwin";
  userName = config._userName;
in {
  imports = [ ./options.nix ];

  config = lib.mkIf cfg.enable {
    _custom.neovim.setBuildEnv = true;
    _custom.neovim.withBuildTools = true;

    environment = {
      systemPackages = with pkgs;
        let
          commonPackages = [
            prevstable-neovim.neovim-remote

            # required by mason
            lua54Packages.luarocks # HACK: it should be necessary here
            go

            # required by https://github.com/toppair/peek.nvim
            deno

            # required by treesitter
            tree-sitter

            # required by null-ls
            statix
            nixfmt

            # required by telescope
            ripgrep
            fd

            # required by nvim-dap
            _custom.customNodePackages.ts-node
          ];
          linuxPackages = [ unstable.neovide ];
        in commonPackages ++ (if (!isDarwin) then linuxPackages else [ ]);
    };

    programs.zsh.shellAliases = { nv = ''run-without-kpadding nvim "$@"''; };

    home-manager.users.${userName} = {
      home.sessionVariables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
      };
    };
  };
}
