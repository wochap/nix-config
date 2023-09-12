{ config, pkgs, lib, inputs, ... }:

let
  userName = config._userName;
  isDarwin = config._displayServer == "darwin";
  customNerdFonts = pkgs.unstable.nerdfonts.override {
    fonts = [
      "FiraCode"
      "FiraMono"
      "Hack"
      "Iosevka"
      "IosevkaTerm"
      "JetBrainsMono"
      "NerdFontsSymbolsOnly"
    ];
  };
in {
  config = {
    fonts = lib.mkMerge [
      {
        fonts = with pkgs; [
          customNerdFonts

          cascadia-code
          fira-code # doesn't have retina

          ibm-plex

          source-serif
          source-sans
          source-code-pro

          cantarell-fonts
        ];
      }
      (if isDarwin then {
        enableFontDir = true;
      } else {
        fontDir.enable = true;
        enableDefaultFonts = true;
        fonts = with pkgs; [
          inter
          unifont # i18n

          corefonts # basic fonts for office
          font-awesome
          font-awesome_4
          material-design-icons
          material-icons
          noto-fonts
          noto-fonts-cjk
          open-sans
          roboto
          roboto-slab

          # emojis
          noto-fonts-emoji
          symbola # i18n
          twitter-color-emoji

          # TODO: doesn't work
          # openmoji-color
        ];
        fontconfig = {
          allowBitmaps = true;
          defaultFonts = {
            serif = [ "Source Serif Pro" ];
            sansSerif = [ "Source Sans Pro" ];
            monospace = [ "Source Code Pro" ];
            # serif = [ "IBM Plex Serif" ];
            # sansSerif = [ "IBM Plex Sans" ];
            # monospace = [ "IBM Plex Mono" ];
            emoji = [ "Twemoji" "Noto Color Emoji" "Symbola" ];
          };
        };
      })
    ];

    home-manager.users.${userName} = {
      home.file = {
        "fontconfig/conf.d/10-nerd-font-symbols-2.1.0.conf".source =
          ./assets/10-nerd-font-symbols.conf.conf;
        ".local/share/fonts/Symbols-1000-em_Nerd_Font_Complete.ttf".source =
          ./assets/Symbols-1000-em_Nerd_Font_Complete.ttf;
        ".local/share/fonts/Symbols-2048-em_Nerd_Font_Complete.ttf".source =
          ./assets/Symbols-2048-em_Nerd_Font_Complete.ttf;
        ".local/share/fonts/nonicons.ttf".source =
          "${inputs.nonicons}/dist/nonicons.ttf";
        ".local/share/fonts/woos.ttf".source = ./assets/woos/fonts/woos.ttf;
      };
    };
  };
}
