{ config, pkgs, lib, inputs, ... }:

let
  userName = config._userName;
  isDarwin = config._displayServer == "darwin";
  customNerdFonts = pkgs.unstable.nerdfonts.override {
    fonts = [
      "FiraCode"
      "Iosevka"
      "IosevkaTerm"
      "NerdFontsSymbolsOnly"
      # "Hack"
      # "JetBrainsMono"
    ];
  };
in {
  config = {
    fonts = lib.mkMerge [
      {
        fonts = with pkgs; [
          customNerdFonts

          source-serif
          source-sans
          source-code-pro

          # cascadia-code
        ];
      }
      (if isDarwin then {
        enableFontDir = true;
      } else {
        fontDir.enable = true;
        enableDefaultFonts = true;
        fonts = with pkgs; [
          # NOTE: uncommenting causes rofi to slow down
          # corefonts # basic fonts for office

          # common
          inter
          open-sans
          roboto
          roboto-slab
          unifont # i18n

          # emojis
          noto-fonts-emoji
          symbola # i18n
          twitter-color-emoji
        ];
        fontconfig = {
          allowBitmaps = true;
          defaultFonts = {
            serif = [ "Source Serif Pro" ];
            sansSerif = [ "Source Sans Pro" ];
            monospace = [ "Source Code Pro" ];
            emoji = [ "Twemoji" "Noto Color Emoji" "Symbola" ];
          };
        };
      })
    ];

    home-manager.users.${userName} = {
      home.file = {
        ".local/share/fonts/nonicons.ttf".source =
          "${inputs.nonicons}/dist/nonicons.ttf";
        ".local/share/fonts/woos.ttf".source = ./assets/woos/fonts/woos.ttf;
      };
    };
  };
}
