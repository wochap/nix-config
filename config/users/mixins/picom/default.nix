{ config, pkgs, lib, ... }:

let
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  mkOutOfStoreSymlink = hmConfig.lib.file.mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory = "${configDirectory}/config/users/mixins/picom";
  customPicom = pkgs.picom.overrideAttrs(o: {
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
in
{
  config = {
    environment = {
      systemPackages = with pkgs; [
        customPicom
      ];
    };

    home-manager.users.${userName} = {
      xdg.configFile = {
        "picom/picom.conf".source = mkOutOfStoreSymlink "${currentDirectory}/dotfiles/picom.conf";
      };
    };
  };
}
