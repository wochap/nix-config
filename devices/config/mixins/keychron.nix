{ config, pkgs, lib, ... }:

let
  localPkgs = import ../packages { pkgs = pkgs; };
in
{
  config = {
    # Enable fn keys on Keychron
    boot = {
      extraModprobeConfig = ''
        options hid_apple fnmode=0
      '';
      kernelParams = [
        "hid_apple.fnmode=0"
      ];
      kernelModules = [
        "hid-apple"
      ];
    };

    # services.interception-tools = {
    #   enable = true;
    #   udevmonConfig = ''
    #     - JOB: "${pkgs.interception-tools}/bin/intercept -g $DEVNODE | ${localPkgs.interception-caps2esc}/bin/caps2esc -m 1 | ${localPkgs.interception-both-shift-capslock}/bin/both-shift-capslock | ${pkgs.interception-tools}/bin/uinput -d $DEVNODE"
    #       DEVICE:
    #         EVENTS:
    #           EV_KEY: [KEY_CAPSLOCK, KEY_LEFTSHIFT, KEY_RIGHTSHIFT]
    #   '';
    #   plugins = [
    #     localPkgs.interception-caps2esc
    #     localPkgs.interception-both-shift-capslock
    #   ];
    # };
  };
}
