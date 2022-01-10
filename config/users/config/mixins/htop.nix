{ config, pkgs, lib, ... }:

let userName = config._userName;
in {
  config = {
    home-manager.users.${userName} = {

      programs.htop = {
        enable = true;
        settings = {
          enable_mouse = true;
          show_program_path = false;
          tree_view = true;
          vim_mode = true;
        };
      };
    };
  };
}

