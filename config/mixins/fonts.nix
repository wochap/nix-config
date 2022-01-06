{ config, pkgs, lib, ... }:

let
  isDarwin = config._displayServer == "darwin";
  customNerdFonts = (pkgs.nerdfonts.override {
    fonts = [
      "FiraCode"
      "FiraMono"
      "Hack"
      "Iosevka"
      "JetBrainsMono"
    ];
  });
in
{
  config = {
    fonts = lib.mkMerge [
      {
        fonts = with pkgs; [
          # TODO: requires nvidia?
          customNerdFonts
        ];
      }
      (if (isDarwin) then {
        enableFontDir = true;
      } else {
        fontDir.enable = true;
        enableDefaultFonts = true;
        fonts = with pkgs; [
          inter
          unifont

          corefonts # basic fonts for office
          symbola
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
        ];
        fontconfig = {
          allowBitmaps = true;
          defaultFonts = {
            serif = [ "Roboto Slab" ];
            sansSerif = [ "Inter" ];
            monospace = [ "FiraCode Nerd Font Mono" ];
            emoji = [ "Noto Color Emoji" ];
          };
        };
      })
    ];
  };
}
