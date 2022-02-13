{ config, pkgs, lib, ... }:

let userName = config._userName;
in {
  config = {
    home-manager.users.${userName} = {
      programs.autorandr = {
        enable = true;
        hooks = {
          postswitch = {
            # TODO: reload bspwm
            # TODO: reload polybar
            "change-background" = "/etc/scripts/random-bg.sh";
            "change-dpi" = builtins.readFile ./scripts/change-dpi.sh;
          };
        };
        profiles = {
          "mbp-i-4k" = {
            fingerprint = {
              DisplayPort-2 =
                "00ffffffffffff001e6d07770cbc0700051e0104b53c22789e3e31ae5047ac270c50542108007140818081c0a9c0d1c08100010101014dd000a0f0703e803020650c58542100001a286800a0f0703e800890650c58542100001a000000fd00383d1e8738000a202020202020000000fc004c472048445220344b0a202020019a0203197144900403012309070783010000e305c000e3060501023a801871382d40582c450058542100001e565e00a0a0a029503020350058542100001a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000029";
            };
            config = {
              DisplayPort-2 = {
                enable = true;
                crtc = 0;
                dpi = 144;
                mode = "3840x2160";
                position = "0x0";
                primary = true;
                rate = "60.00";
              };
            };
          };

          "mbp-i" = {
            fingerprint = {
              eDP1 =
                "00ffffffffffff0006102fa00000000004190104a5211578026fb1a7554c9e250c505400000001010101010101010101010101010101ef8340a0b0083470302036004bcf1000001a000000fc00436f6c6f72204c43440a20202000000010000000000000000000000000000000000010000000000000000000000000000000cf";
            };
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
            fingerprint = {
              eDP =
                "00ffffffffffff0006102fa00000000004190104a5211578026fb1a7554c9e250c505400000001010101010101010101010101010101ef8340a0b0083470302036004bcf1000001a000000fc00436f6c6f72204c43440a20202000000010000000000000000000000000000000000010000000000000000000000000000000cf";
            };
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
          "desktop-4k" = {
            fingerprint = {
              HDMI-0 =
                "00ffffffffffff001e6d06770cbc0700051e0103803c2278ea3e31ae5047ac270c50542108007140818081c0a9c0d1c081000101010108e80030f2705a80b0588a0058542100001e04740030f2705a80b0588a0058542100001a000000fd00383d1e873c000a202020202020000000fc004c472048445220344b0a202020010c020338714d9022201f1203040161605d5e5f230907076d030c001000b83c20006001020367d85dc401788003e30f0003e305c000e3060501023a801871382d40582c450058542100001e565e00a0a0a029503020350058542100001a000000ff003030354e54455045573839320a0000000000000000000000000000000000cc";
              DP-2 =
                "00ffffffffffff0006b3af249bf600001c1e0104a5351e783b51b5a4544fa0260d5054bfcf00814081809500714f81c0b30001010101023a801871382d40582c45000f282100001e0882805070384d400820f80c0f282100001a000000fd003090b4b422010a202020202020000000fc00415355532056503234390a2020014e020322f14d010304131f120211900e0f1d1e230907078301000067030c0010000044fe5b80a070383540302035000f282100001a866f80a070384040302035000f282100001a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b";
            };
            config = {
              DP-2.enable = false;
              HDMI-0 = {
                enable = true;
                crtc = 0;
                dpi = 144;
                mode = "3840x2160";
                position = "0x0";
                primary = true;
                rate = "60.00";
              };
            };
          };
          "desktop-1080p" = {
            fingerprint = {
              HDMI-0 =
                "00ffffffffffff001e6d06770cbc0700051e0103803c2278ea3e31ae5047ac270c50542108007140818081c0a9c0d1c081000101010108e80030f2705a80b0588a0058542100001e04740030f2705a80b0588a0058542100001a000000fd00383d1e873c000a202020202020000000fc004c472048445220344b0a202020010c020338714d9022201f1203040161605d5e5f230907076d030c001000b83c20006001020367d85dc401788003e30f0003e305c000e3060501023a801871382d40582c450058542100001e565e00a0a0a029503020350058542100001a000000ff003030354e54455045573839320a0000000000000000000000000000000000cc";
              DP-2 =
                "00ffffffffffff0006b3af249bf600001c1e0104a5351e783b51b5a4544fa0260d5054bfcf00814081809500714f81c0b30001010101023a801871382d40582c45000f282100001e0882805070384d400820f80c0f282100001a000000fd003090b4b422010a202020202020000000fc00415355532056503234390a2020014e020322f14d010304131f120211900e0f1d1e230907078301000067030c0010000044fe5b80a070383540302035000f282100001a866f80a070384040302035000f282100001a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b";
            };
            config = {
              HDMI-0.enable = false;
              DP-2 = {
                enable = true;
                crtc = 0;
                dpi = 96;
                mode = "1920x1080";
                position = "0x0";
                primary = true;
                rate = "144.00";
              };
            };
          };
        };
      };
    };
  };
}
