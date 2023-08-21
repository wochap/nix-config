{ config, pkgs, lib, ... }:

let
  cfg = config._custom.xorgWm;
  userName = config._userName;
  mbpEdid =
    "00ffffffffffff0006102fa00000000004190104a5211578026fb1a7554c9e250c505400000001010101010101010101010101010101ef8340a0b0083470302036004bcf1000001a000000fc00436f6c6f72204c43440a20202000000010000000000000000000000000000000000010000000000000000000000000000000cf";
  lgUWEdid =
    "00ffffffffffff001e6d4b77a8860a000c1f0104b55021789ff675af4e42ab260e50542109007140818081c0a9c0b300d1c08100d1cfdaa77050d5a0345090203a30204f3100001a000000fd003090e1e150010a202020202020000000fc004c4720554c545241474541520a000000ff003131324e544c454c393833320a0200020330712309070747100403011f131283010000e305c000e2006ae606050161613d6d1a0000020530900004613d613d4ed470d0d0a0325030203a00204f3100001a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ee7012790000030114663801866f0def002f801f009f0545000200090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b90";
in {
  config = lib.mkIf cfg.enable {
    home-manager.users.${userName} = {
      programs.autorandr = {
        enable = true;
        hooks = {
          postswitch = {
            "change-background" = "/etc/scripts/random-bg.sh";
            "change-dpi" = builtins.readFile ./scripts/change-dpi.sh;
          };
        };
        profiles = {

          "mbp-i" = {
            fingerprint = { eDP1 = mbpEdid; };
            config = {
              eDP1 = {
                enable = true;
                crtc = 0;
                dpi = 192;
                mode = "2880x1800";
                position = "0x0";
                primary = true;
                rate = "59.99";
              };
            };
          };

          "mbp" = {
            fingerprint = { eDP = mbpEdid; };
            config = {
              eDP = {
                enable = true;
                crtc = 0;
                dpi = 192;
                mode = "2880x1800";
                position = "0x0";
                primary = true;
                rate = "59.99";
              };
            };
          };

          "mbp-uw" = {
            fingerprint = {
              eDP = mbpEdid;
              DisplayPort-0 = lgUWEdid;
            };
            config = {
              eDP.enable = false;
              DisplayPort-0 = {
                enable = true;
                crtc = 0;
                dpi = 96;
                mode = "3440x1440";
                position = "0x0";
                primary = true;
                rate = "99.99";
              };
            };
          };

          "desktop-uw" = {
            fingerprint = { DisplayPort-0 = lgUWEdid; };
            config = {
              DisplayPort-0 = {
                enable = true;
                crtc = 0;
                dpi = 96;
                mode = "3440x1440";
                position = "0x0";
                primary = true;
                rate = "143.92";
              };
            };
          };

        };
      };
    };
  };
}
