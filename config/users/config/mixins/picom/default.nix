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
        experimentalBackends = true;

        extraOptions = (builtins.readFile ./dotfiles/picom.conf);
        package = pkgs.picom.overrideAttrs(o: {
          src = pkgs.fetchFromGitHub {
            # # No blur, aceptable fix for screen tearing but... artifacts++
            # repo = "picom";
            # owner = "yshui";
            # # next branch
            # rev = "6555703b03fed197f6ff7fe6ddbd5a249c253ac3";
            # sha256 = "sha256-WDx5WCND1UGszaAILbk+bU0VN9/mCLLZ9evHIbUi1B8=";

            # # Stable picom
            # repo = "picom";
            # owner = "yshui";
            # # v8.2 branch
            # rev = "dac85eac10082dfc3df463aaa74b811144e22122ht";
            # sha256 = "0gjksayz2xpmgglvw17ppsan2imrd1fijs579kbf27xwp503xgfl";

            # Aceptable fix for screen tearing but... artifacts+ (WORKS)
            repo = "picom";
            owner = "ibhagwan";
            # next-rebase branch
            rev = "c4107bb6cc17773fdc6c48bb2e475ef957513c7a";
            sha256 = "sha256-1hVFBGo4Ieke2T9PqMur1w4D0bz/L3FAvfujY9Zergw=";
          };
        });
      };
    };
  };
}
