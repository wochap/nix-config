{ config, lib, ... }:

let cfg = config._custom.programs.less;
in {
  options._custom.programs.less.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.sessionVariables = {
        LESS = "--ignore-case --RAW-CONTROL-CHARS --LONG-PROMPT";
        LESSCHARSET = "utf-8";
      };

      programs.less = {
        enable = true;
        keys = ''
          f forw-line 4j
          b back-line 4k
        '';
      };
    };
  };
}

