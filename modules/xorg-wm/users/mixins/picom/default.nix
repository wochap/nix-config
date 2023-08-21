{ config, pkgs, lib, ... }:

let
  cfg = config._custom.xorgWm;
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  inherit (hmConfig.lib.file) mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory = "${configDirectory}/modules/xorg-wm/users/mixins/picom";
  customPicom = pkgs.picom.overrideAttrs(o: {
    src = pkgs.fetchFromGitHub {
      # No blur?
      repo = "picom";
      owner = "yshui";
      # next branch
      rev = "aa316aa3601a4f3ce9c1ca79932218ab574e61a7";
      sha256 = "sha256-Yb69LTu45HxBWoD/T9Uj6b1lNn7hHzIEjcn73PMMEz0=";

      # # Aceptable fix for screen tearing but... artifacts+ (WORKS)
      # # Round corners with shadows
      # repo = "picom";
      # owner = "ibhagwan";
      # # next-rebase branch
      # rev = "c4107bb6cc17773fdc6c48bb2e475ef957513c7a";
      # sha256 = "sha256-1hVFBGo4Ieke2T9PqMur1w4D0bz/L3FAvfujY9Zergw=";

      # # Animations
      # repo = "picom";
      # owner = "jonaburg";
      # rev = "a8445684fe18946604848efb73ace9457b29bf80";
      # sha256 = "sha256-1hVFBGo4Ieke2T9PqMur1w4D0bz/L5FAvfujY9Zergw=";
    };
  });
in
{
  config = lib.mkIf cfg.enable {
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
