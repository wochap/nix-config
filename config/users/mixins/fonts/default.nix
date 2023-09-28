{ config, pkgs, lib, inputs, ... }:

let
  userName = config._userName;
  isDarwin = config._displayServer == "darwin";
  customNerdFonts = pkgs.unstable.nerdfonts.override {
    fonts = [
      "FiraCode"
      "Iosevka"
      "NerdFontsSymbolsOnly"
      # "FiraMono"
      # "Hack"
      # "IosevkaTerm"
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
          # fira-code # doesn't have retina
          # ibm-plex
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
          noto-fonts
          noto-fonts-cjk
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
        # "fontconfig/conf.d/10-nerd-font-symbols-2.1.0.conf".source =
        #   ./assets/10-nerd-font-symbols.conf.conf;
        # ".local/share/fonts/Symbols-1000-em_Nerd_Font_Complete.ttf".source =
        #   ./assets/Symbols-1000-em_Nerd_Font_Complete.ttf;
        # ".local/share/fonts/Symbols-2048-em_Nerd_Font_Complete.ttf".source =
        #   ./assets/Symbols-2048-em_Nerd_Font_Complete.ttf;
        ".local/share/fonts/nonicons.ttf".source =
          "${inputs.nonicons}/dist/nonicons.ttf";
        ".local/share/fonts/woos.ttf".source = ./assets/woos/fonts/woos.ttf;
      };
    };
  };
}
