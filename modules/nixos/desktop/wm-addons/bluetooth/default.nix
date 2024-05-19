{ config, pkgs, lib, ... }:

let cfg = config._custom.desktop.bluetooth;
in {
  options._custom.desktop.bluetooth.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        bluetuith # bluetooth TUI
        blueberry # bluetooth GUI
        modemmanager

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
        # Possible values: true or false
        Experimental = true;

        # Enables kernel experimental features, alternatively a list of UUIDs
        # can be given.
        # Possible values: true,false,<UUID List>
        # Possible UUIDS:
        # Defaults to false.
        KernelExperimental = true;

        Enable = "Control,Gateway,Headset,Media,Sink,Socket,Source";
      };
      # Policy = { AutoEnable = false; };
    };

    # source: https://wiki.archlinux.org/title/PipeWire#Noticeable_audio_delay_or_audible_pop/crack_when_starting_playback
    services.pipewire.wireplumber.configPackages = [
      (pkgs.writeTextDir
        "share/wireplumber/wireplumber.conf.d/51-disable-suspension.conf" ''
          monitor.alsa.rules = [
            {
              matches = [
                {
                  # Matches all sources
                  node.name = "~alsa_input.*"
                },
                {
                  # Matches all sinks
                  node.name = "~alsa_output.*"
                }
              ]
              actions = {
                update-props = {
                  session.suspend-timeout-seconds = 0
                }
              }
            }
          ]
          # bluetooth devices
          monitor.bluez.rules = [
            {
              matches = [
                {
                  # Matches all sources
                  node.name = "~bluez_input.*"
                },
                {
                  # Matches all sinks
                  node.name = "~bluez_output.*"
                }
              ]
              actions = {
                update-props = {
                  session.suspend-timeout-seconds = 0
                  dither.method = "wannamaker3",
                  dither.noise = 2,
                }
              }
            }
          ]
        '')
    ];

    _custom.hm = {
      # proxy forwarding Bluetooth MIDI controls via MPRIS2 to control media players
      services.mpris-proxy.enable = true;
    };
  };
}
