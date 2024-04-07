{ config, pkgs, lib, ... }:

let cfg = config._custom.dev.lang-c;
in {
  options._custom.dev.lang-c.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      # TODO: override CPLUS_INCLUDE_PATH?

      home.packages = with pkgs; [
        # generates .cache and compile_commands.json
        # files required by clangd
        bear

        # provides clangd (LSP)
        # provides libraries
        # NOTE: make sure mason.nvim don't install clangd
        clang-tools

        # required by codelldb (debugger)
        # lldb # libraries conflicts with clang-tools
        gdb
      ];
    };
  };
}
