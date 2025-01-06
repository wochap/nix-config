{ config, pkgs, lib, ... }:

let
  cfg = config._custom.programs.lang-lua;
  inherit (config._custom.globals) configDirectory;
in {
  options._custom.programs.lang-lua.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      lua51Packages.lua
      lua51Packages.luarocks
      lua51Packages.tiktoken_core
    ];

    _custom.hm = {
      xdg.configFile."luarocks/config-5.1.lua".source =
        lib._custom.relativeSymlink configDirectory ./dotfiles/config-5.1.lua;
    };
  };
}

