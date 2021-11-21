{ config, pkgs, lib, ... }:

let
  isDarwin = config._displayServer == "darwin";
in
{
  config = {
    fonts = {
      fontDir.enable = true;
      enableDefaultFonts = true;
      fonts = with pkgs; [
        inter
        unifont

        # TODO: requires nvidia?
        (nerdfonts.override {
          fonts = [
            "FiraCode"
            "FiraMono"
            "Hack"
            "Iosevka"
            "JetBrainsMono"
          ];
        })
      ] ++ (if (!isDarwin) then [
        corefonts # basic fonts for office
        font-awesome
        font-awesome_4
        material-icons
        noto-fonts
        noto-fonts-cjk
        noto-fonts-emoji
        open-sans
        roboto
        roboto-slab
        siji
        terminus_font
      ] else []);
      fontconfig = lib.mkIf (!isDarwin) {
        allowBitmaps = true;
        defaultFonts = {
          serif = [ "Roboto Slab" ];
          sansSerif = [ "Inter" ];
          monospace = [ "FiraCode Nerd Font Mono" ];
          emoji = [ "Noto Color Emoji" ];
        };
      };
    };
  };
}
