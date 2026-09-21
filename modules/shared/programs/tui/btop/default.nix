{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:

let
  cfg = config._custom.programs.btop;
  inherit (config._custom.globals)
    # themeColorsLight
    # themeColorsDark
    # preferDark
    configDirectory
    ;
in
{
  options._custom.programs.btop = {
    enable = lib.mkEnableOption { };
    enableCuda = lib.mkEnableOption { };
    enableRocm = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs; [
        (
          if cfg.enableCuda then pkgs.btop-cuda else (if cfg.enableRocm then pkgs.btop-rocm else pkgs.btop)
        )
      ];

      home.shellAliases.top = "btop";

      xdg.configFile = {
        "btop/btop.conf".source = lib._custom.relativeSymlink configDirectory ./dotfiles/btop.conf;
        "btop/themes".source = "${inputs.catppuccin-btop}/themes";
      };
    };
  };
}
