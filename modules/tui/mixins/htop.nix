{ config, pkgs, lib, ... }:

let
  cfg = config._custom.tui.htop;
  userName = config._userName;
in {
  options._custom.tui.htop = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    home-manager.users.${userName} = {

      programs.htop = {
        enable = true;
        settings = {
          enable_mouse = true;
          show_program_path = false;
          tree_view = true;
          vim_mode = true;
          hide_userland_threads = true;
          highlight_base_name = true;
        };
      };
    };
  };
}
