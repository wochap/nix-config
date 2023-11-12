{ config, pkgs, lib, ... }:

let
  cfg = config._custom.services.interception-tools;
  mbpKeyboard =
    "/dev/input/by-id/usb-Apple_Inc._Apple_Internal_Keyboard___Trackpad_D3H54961U11GHMFA75BS-if01-event-kbd";
  keychrone = "/dev/input/by-id/usb-Keychron_Keychron_K3-event-kbd";
  generateJob = devnode:
    with pkgs; ''
      - JOB: "if [ -e $DEVNODE ]; then ${interception-tools}/bin/intercept -g $DEVNODE | ${interception-tools-plugins.caps2esc}/bin/caps2esc -m 1 | ${_custom.interception-both-shift-capslock}/bin/both-shift-capslock | ${interception-tools}/bin/uinput -d $DEVNODE; fi"
        DEVICE:
          LINK: "${devnode}"
          EVENTS:
            EV_KEY: [KEY_CAPSLOCK, KEY_LEFTSHIFT, KEY_RIGHTSHIFT]
    '';
in {
  options._custom.services.interception-tools = {
    enable = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    services.interception-tools.enable = true;
    services.interception-tools.plugins = with pkgs; [
      interception-tools-plugins.caps2esc
      _custom.interception-both-shift-capslock
    ];
    services.interception-tools.udevmonConfig = ''
      ${generateJob mbpKeyboard}
      ${generateJob keychrone}
    '';
  };
}
