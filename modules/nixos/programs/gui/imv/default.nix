{ config, pkgs, lib, ... }:

let
  cfg = config._custom.programs.imv;
  inherit (config._custom.globals) themeColors;
  imv-final = pkgs.imv.override {
    withBackends = [ "libjxl" "libtiff" "libjpeg" "libpng" "librsvg" "libheif" ]
      ++ (lib.optional cfg.enableInsecureFreeImage "freeimage");
  };
in {
  options._custom.programs.imv.enable = lib.mkEnableOption { };
  options._custom.programs.imv.enableInsecureFreeImage = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs; [ imv-final ];

      xdg.configFile = {
        "imv/config".text = lib.generators.toINI { } {
          options = {
            background = themeColors.background;
            overlay_text_color = themeColors.text;
            overlay_background_color = themeColors.backgroundOverlay;
            overlay = true;
            overlay_font = "Iosevka NF:10";
            overlay_position_bottom = true;
            scaling_mode = "shrink";
          };
          binds = {
            gy = ''exec echo "$imv_current_file" | wl-copy'';
            e = ''
              exec swappy -f "$imv_current_file" -o "$imv_current_file" &; quit'';
            r = ''exec mogrify -rotate 90 "$imv_current_file" &;'';
            "<Ctrl+Shift+D>" = ''exec rm "$imv_current_file"; quit'';
            "<Shift+D>" = ''exec rm "$imv_current_file"; close'';
          };
        };
      };
    };
  };
}
