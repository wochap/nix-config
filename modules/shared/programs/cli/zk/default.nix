{ config, pkgs, lib, ... }:

let
  cfg = config._custom.programs.zk;
  inherit (config._custom.globals) configDirectory;
in {
  options._custom.programs.zk.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs; [ zk ];

      home.sessionVariables.ZK_NOTEBOOK_DIR = "$HOME/Sync/zk";

      xdg.configFile."zk".source = lib._custom.relativeSymlink configDirectory ./dotfiles;
    };
  };
}
