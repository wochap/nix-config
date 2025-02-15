{ config, pkgs, lib, ... }:

let
  cfg = config._custom.desktop.fonts;
  isDarwin = pkgs.stdenv.isDarwin;
  inherit (config._custom.globals) fonts;
  customNerdFonts = pkgs.nerdfonts.override {
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
  options._custom.desktop.fonts.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    fonts = lib.mkMerge [
      {
        packages = with pkgs; [
          customNerdFonts

          source-serif
          source-sans
          source-code-pro
          source-sans-pro

          # cascadia-code
        ];
      }
      (lib.mkIf isDarwin { enableFontDir = true; })
      (lib.mkIf (!isDarwin) {
        fontDir.enable = true;
        enableDefaultPackages = true;
        packages = with pkgs; [
          # NOTE: uncommenting causes rofi to slow down
          corefonts # basic fonts for office
          vistafonts # more ms fonts

          # common
          inter
          open-sans
          roboto
          roboto-slab
          unifont # i18n
          noto-fonts-cjk-sans # jp, kr, sc, tc, hk chars

          # emojis
          noto-fonts-emoji
          symbola # i18n
          twitter-color-emoji
        ];
        fontconfig = {
          allowBitmaps = true;
          defaultFonts = {
            serif = [ "Source Serif Pro" ];
            sansSerif = [ fonts.sans ];
            monospace = [ "Source Code Pro" ];
            emoji = [ "Twemoji" "Noto Color Emoji" "Symbola" ];
          };
        };
      })
    ];

    _custom.hm.home.file.".local/share/fonts/woos.ttf".source =
      ./assets/woos/fonts/woos.ttf;
  };
}
