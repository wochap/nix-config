{ config, pkgs, lib, ... }:

let cfg = config._custom.dev.lang-c;
in {
  options._custom.dev.lang-c.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs;
        [
          # provides clangd
          # provides libraries
          # NOTE: make sure mason.nvim don't install clangd
          clang-tools
        ];
    };
  };
}
