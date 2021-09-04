{ config, pkgs, lib, ... }:

let
  userName = config._userName;
  isXorg = config._displayServer == "xorg";
in
{
  config = {
    home-manager.users.${userName} = {
      services.picom = lib.mkIf isXorg {
        enable = true;

        noDockShadow = false;
        vSync = true;
        backend = "glx";
        # Disabling experimentalBackends, removes corners artifact with shadows
        experimentalBackends = false;

        extraOptions = (builtins.readFile ./dotfiles/picom.conf);
        package = pkgs.picom.overrideAttrs(o: {
          src = pkgs.fetchFromGitHub {
            # # No blur, aceptable fix for screen tearing but... artifacts++
            # repo = "picom";
            # owner = "yshui";
            # # next branch
            # rev = "fd381dacff5c755b43effba441fb5706a0f378a4";
            # sha256 = "0za3ywdn27dzp7140cpg1imbqpbflpzgarr76xaqmijz97rv1909";

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

            # Aceptable fix for screen tearing but... artifacts+ (WORKS)
            repo = "picom";
            owner = "ibhagwan";
            # next-rebase branch
            rev = "60eb00ce1b52aee46d343481d0530d5013ab850b";
            sha256 = "1m17znhl42sa6ry31yiy05j5ql6razajzd6s3k2wz4c63rc2fd1w";
          };
        });
      };
    };
  };
}
