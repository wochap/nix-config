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

    services.interception-tools = {
      enable = true;
      udevmonConfig = ''
        - JOB: "intercept -g $DEVNODE | caps2esc -m 1 | both-shift-capslock | uinput -d $DEVNODE"
          DEVICE:
            EVENTS:
              EV_KEY: [KEY_CAPSLOCK, KEY_LEFTSHIFT, KEY_RIGHTSHIFT]
      '';
      plugins = [
        pkgs.interception-tools-plugins.caps2esc
        localPkgs.interception-both-shift-capslock
      ];
    };
  };
}
