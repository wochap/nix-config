{ config, pkgs, lib, ... }:

let
  cfg = config._custom.programs.lang-ruby;
  inherit (config._custom.globals) configDirectory;
in {
  options._custom.programs.lang-ruby.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ ruby ];

    _custom.hm = {
      home = {
        # Gemfile for LSP, formatters, linters, etc
        sessionVariables.GLOBAL_GEMFILE = "$HOME/.gem/global/Gemfile";

        file = {
          ".gem/global/Gemfile".source =
            lib._custom.relativeSymlink configDirectory ./dotfiles/Gemfile;
        };
      };
    };
  };
}

