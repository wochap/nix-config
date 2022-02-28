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
        ".local/share/fonts/nonicons.ttf".source = "${inputs.nonicons}/dist/nonicons.ttf";
        # "fontconfig/conf.d/10-nerd-font-symbols.conf".source =
      };
    };
  };
}
