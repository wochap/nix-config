{ config, pkgs, lib, inputs, ... }:

let
  userName = config._userName;
  isDarwin = config._displayServer == "darwin";
  customNerdFonts = (pkgs.nerdfonts.override {
    fonts = [ "FiraCode" "FiraMono" "Hack" "Iosevka" "JetBrainsMono" ];
  });
in {
  config = {
    fonts = lib.mkMerge [
      {
        fonts = with pkgs; [
          fira-code
          cascadia-code
          customNerdFonts
          source-code-pro
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
          material-design-icons
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
            sansSerif = [ "JetBrainsMono Nerd Font" ];
            monospace = [ "JetBrainsMono Nerd Font" ];
            emoji = [ "Noto Color Emoji" ];
          };
        };
      })
    ];

    home-manager.users.${userName} = {
      home.file = {
        "fontconfig/conf.d/10-nerd-font-symbols-2.1.0.conf".source = ./assets/10-nerd-font-symbols.conf.conf;
        ".local/share/fonts/Symbols-1000-em_Nerd_Font_Complete.ttf".source = ./assets/Symbols-1000-em_Nerd_Font_Complete.ttf;
        ".local/share/fonts/Symbols-2048-em_Nerd_Font_Complete.ttf".source = ./assets/Symbols-2048-em_Nerd_Font_Complete.ttf;
        ".local/share/fonts/nonicons.ttf".source = "${inputs.nonicons}/dist/nonicons.ttf";
        ".local/share/fonts/woos.ttf".source = ./assets/woos/fonts/woos.ttf;
      };
    };
  };
}
