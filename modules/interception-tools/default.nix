{ config, pkgs, lib, ... }:

let
  userName = config._userName;
  cfg = config._custom.interception-tools;
in {
  options._custom.interception-tools = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    services.interception-tools.enable = true;
    services.interception-tools.plugins = with pkgs; [
      interception-tools-plugins.caps2esc
      _custom.interception-both-shift-capslock
    ];
    services.interception-tools.udevmonConfig = with pkgs; ''
      - JOB: "${interception-tools}/bin/intercept -g $DEVNODE | ${interception-tools-plugins.caps2esc}/bin/caps2esc -m 1 | ${_custom.interception-both-shift-capslock}/bin/both-shift-capslock | ${interception-tools}/bin/uinput -d $DEVNODE"
        DEVICE:
          EVENTS:
            EV_KEY: [KEY_CAPSLOCK, KEY_LEFTSHIFT, KEY_RIGHTSHIFT]
    '';
  };
}
