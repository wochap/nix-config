{ config, pkgs, lib, inputs, ... }:

let
  userName = config._userName;
  cfg = config._custom.wm.bluetooth;
in {
  options._custom.wm.bluetooth = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        bluetuith # bluetooth TUI
        modemmanager

        bluez
        bluez-tools
      ];
    };

    # Enable bluetooth
    hardware.bluetooth.enable = true;
    hardware.bluetooth.powerOnBoot = true;
    hardware.bluetooth.settings = {
      General = {
        # Enables D-Bus experimental interfaces
        # Possible values: true or false
        Experimental = true;

        # Enables kernel experimental features, alternatively a list of UUIDs
        # can be given.
        # Possible values: true,false,<UUID List>
        # Possible UUIDS:
        # Defaults to false.
        KernelExperimental = true;
      };
      # Policy = { AutoEnable = false; };
    };

    home-manager.users.${userName} = {
      # proxy forwarding Bluetooth MIDI controls via MPRIS2 to control media players
      services.mpris-proxy.enable = true;
    };
  };
}
