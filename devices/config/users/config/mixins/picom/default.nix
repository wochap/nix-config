{ config, pkgs, lib, ... }:

let
  isXorg = config._displayServer == "xorg";
in
{
  config = {
    home-manager.users.gean = {
      services.picom = lib.mkIf isXorg {
        enable = true;

        noDockShadow = false;
        vSync = true;
        backend = "glx";
        # Disabling experimentalBackends, removes corners artifact with shadows
        experimentalBackends = true;
        # opacityRule = [
        #   "90:class_i ?= 'thunar'"
        # ];

        extraOptions = (builtins.readFile ./dotfiles/picom.conf);
        package = pkgs.picom.overrideAttrs(o: {
          src = pkgs.fetchFromGitHub {
            # No blur, aceptable fix for screen tearing but... artifacts++
            repo = "picom";
            owner = "yshui";
            # next branch
            rev = "7ba87598c177092a775d5e8e4393cb68518edaac";
            sha256 = "0za3ywdn27dzp7140cpg1imbqpbflpzgarr76xaqmijz97rv1909";

            # # Stable picom
            # repo = "picom";
            # owner = "yshui";
            # # v8.2 branch
            # rev = "dac85eac10082dfc3df463aaa74b811144e22122ht";
            # sha256 = "0gjksayz2xpmgglvw17ppsan2imrd1fijs579kbf27xwp503xgfl";

            # # Least screen tearing but... artifacts
            # repo = "picom";
            # owner = "ibhagwan";
            # # next branch
            # rev = "0539616510d9ad339f1af685e9ee39183a8f3562";
            # sha256 = "1z51xk9vdy5l925msmprmhzjis516h76id2qhdswf916ssjgxl6m";

            # # Aceptable fix for screen tearing but... artifacts+ (WORKS)
            # repo = "picom";
            # owner = "ibhagwan";
            # # next-rebase branch
            # rev = "6d87428f78a46bea295e0a21d23c4b56133aadc3";
            # sha256 = "0b5yjgwrndg01l1v2d76b96176k9n6638v73kfr9453crzizzyli";
          };
        });
      };
    };
  };
}
