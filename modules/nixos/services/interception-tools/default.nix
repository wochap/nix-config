{ config, pkgs, lib, ... }:

let
  cfg = config._custom.services.interception-tools;
  keychrone = "/dev/input/by-id/usb-Keychron_Keychron_K3-event-kbd";
  legionKb = "/dev/input/by-id/usb-ITE_Tech._Inc._ITE_Device_8910_-event-kbd";
  generateJob = devnode:
    with pkgs; ''
      - JOB: "if [ -e $DEVNODE ]; then ${interception-tools}/bin/intercept -g $DEVNODE | ${interception-tools-plugins.caps2esc}/bin/caps2esc -m 1 | ${_custom.interception-both-shift-capslock}/bin/both-shift-capslock | ${interception-tools}/bin/uinput -d $DEVNODE; fi"
        DEVICE:
          LINK: "${devnode}"
          EVENTS:
            EV_KEY: [KEY_CAPSLOCK, KEY_LEFTSHIFT, KEY_RIGHTSHIFT]
    '';
in {
  options._custom.services.interception-tools.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ interception-tools ];

    services.interception-tools = {
      enable = true;
      plugins = with pkgs; [
        interception-tools-plugins.caps2esc
        _custom.interception-both-shift-capslock
      ];
      udevmonConfig = ''
        ${generateJob keychrone}
        ${generateJob legionKb}
      '';
    };

    systemd.services.interception-tools.after = [ "multi-user.target" ];
  };
}
