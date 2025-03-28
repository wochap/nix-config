{ config, pkgs, lib, ... }:

let
  cfg = config._custom.programs.lang-ruby;
  inherit (config._custom.globals) configDirectory;
in {
  options._custom.programs.lang-ruby.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    # NOTE: Every time you upgrade Ruby, you should also consider
    # deleting the previous `~/.gem/ruby/x.x.x` directory
    environment.systemPackages = with pkgs; [ ruby ];

    _custom.hm = {
      home = {
        # Gemfile for LSP, formatters, linters, etc
        # It is used by my neovim config
        sessionVariables.GLOBAL_GEMFILE = "$HOME/.gem/global/Gemfile";

        file = {
          ".gem/global/Gemfile".source =
            lib._custom.relativeSymlink configDirectory ./dotfiles/Gemfile;
        };
      };
    };
  };
}

