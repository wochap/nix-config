{ config, pkgs, lib,  ... }:

{
  config = {
    home-manager.users.gean = {
      # Edit linked files
      xdg.configFile = {
        "fish/config.fish".text = lib.mkAfter (builtins.readFile ./dotfiles/config.fish);
      };
      programs.fish = {
        enable = true;
        plugins = [
          {
            name = "z";
            src = pkgs.fetchFromGitHub {
              owner = "jethrokuan";
              repo = "z";
              rev = "ddeb28a7b6a1f0ec6dae40c636e5ca4908ad160a";
              sha256 = "0c5i7sdrsp0q3vbziqzdyqn4fmp235ax4mn4zslrswvn8g3fvdyh";
            };
          }
          # {
          #   name = "eclm";
          #   src = pkgs.fetchFromGitHub {
          #     owner = "oh-my-fish";
          #     repo = "theme-eclm";
          #     rev = "bd9abe5c5d0490a0b16f2aa303838a2b2cc98844";
          #     sha256 = "051wzwn4wr53mq27j1hra7y84y3gyqxgdgg2rwbc5npvbgvdkr09";
          #   };
          # }
          {
            name = "pure";
            src = pkgs.fetchFromGitHub {
              owner = "pure-fish";
              repo = "pure";
              rev = "081f81cd6c32a44f92c0c98cc93d64d035f5dddd";
              sha256 = "0405paylqjf0nw6hcd3bbpazb5w851111w5bxx41y22a3b0639fc";
            };
          }
        ];
      };
    };
  };
}
