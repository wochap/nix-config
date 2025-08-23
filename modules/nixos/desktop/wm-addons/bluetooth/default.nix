{ config, pkgs, lib, ... }:

let
  cfg = config._custom.desktop.bluetooth;
  unblock-bluetooth = pkgs.writeScriptBin "unblock-bluetooth"
    (builtins.readFile ./scripts/unblock-bluetooth.sh);
in {
  options._custom.desktop.bluetooth.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        unblock-bluetooth

        bluetuith # bluetooth TUI
        blueberry # bluetooth GUI
        # modemmanager # cellular service 3G/4G/5G

        bluez
        bluez-tools
      ];

      shellAliases.btui = "bluetuith";
    };

    # Enable bluetooth
    hardware.bluetooth.enable = true;
    hardware.bluetooth.powerOnBoot = lib.mkDefault true;
    hardware.bluetooth.settings = {
      General = {
        # Enables D-Bus experimental interfaces
        Experimental = true;

        # Enables kernel experimental features, alternatively a list of UUIDs can be given.
        KernelExperimental = true;

        PairableTimeout = 0;
        DiscoverableTimeout = 0;
      };
      Policy = {
        # https://askubuntu.com/a/1448936
        ReconnectAttempts = 2;
      };
    };

    # Fix "ConfigurationDirectory 'bluetooth' already exists but the mode is different"
    systemd.services.bluetooth.serviceConfig.ConfigurationDirectoryMode =
      "0755";

    _custom.hm = {
      # prevents bluetooth speaker to turn off
      xdg.configFile."wireplumber/wireplumber.conf.d/51-disable-suspension.conf" =
        {
          source = ./dotfiles/51-disable-suspension.conf;
          force = true;
        };

      # proxy forwarding Bluetooth MIDI controls via MPRIS2 to control media players
      services.mpris-proxy.enable = true;

      # HACK: unblock bluetooth device
      systemd.user.services.unblock-bluetooth = lib._custom.mkWaylandService {
        Service = {
          Type = "oneshot";
          ExecStart = "${unblock-bluetooth}/bin/unblock-bluetooth";
        };
      };
    };
  };
}
