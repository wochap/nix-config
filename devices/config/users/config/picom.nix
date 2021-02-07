{ config, pkgs, lib, ... }:

let
  isXorg = config._displayServer == "xorg";
in
{
  config = {
    home-manager.users.gean = {
      services.picom = lib.mkIf isXorg {
        enable = true;

        # Disabling experimentalBackends, removes corners artifact with shadows
        experimentalBackends = true;

        vSync = true;
        backend = "glx";
        extraOptions = (builtins.readFile ./dotfiles/picom.conf);
        package = pkgs.picom.overrideAttrs(o: {
          src = pkgs.fetchFromGitHub {
            # # No blur, aceptable fix for screen tearing but... artifacts++
            # repo = "picom";
            # owner = "yshui";
            # rev = "3680d323f5edf2ef5f21ab70a272358708c87a22";
            # sha256 = "0wp91y6y2klbpcg8dn4h8bmbns759hak4r3paifgia5b3mmn4lr9";

            # Least screen tearing but... artifacts
            repo = "picom";
            owner = "ibhagwan";
            # next branch
            rev = "0539616510d9ad339f1af685e9ee39183a8f3562";
            sha256 = "1z51xk9vdy5l925msmprmhzjis516h76id2qhdswf916ssjgxl6m";

            # # Aceptable fix for screen tearing but... artifacts+
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
