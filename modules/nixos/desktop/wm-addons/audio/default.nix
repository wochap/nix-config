{ config, lib, inputs, ... }:

let cfg = config._custom.desktop.audio;
in {
  options._custom.desktop.audio.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.user.extraGroups = [ "audio" ];

    hardware.pulseaudio.enable = false;

    hardware.enableAllFirmware = true;

    # suppress background noice
    programs.noisetorch.enable = true;

    # Enable audio
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      # If you want to use JACK applications, uncomment this
      # jack.enable = true;

      wireplumber.enable = true;
    };

    _custom.hm = {
      # alternative to Dolby Atmos
      services.easyeffects = {
        enable = true;
        preset = "Perfect EQ";
      };
      xdg.configFile."easyeffects/output" = {
        source = inputs.easy-effects-presets;
        recursive = true;
      };
    };

    # I copy the following from other user config
    # systemd.user.services = {
    #   pipewire-pulse = {
    #     path = [ pkgs.pulseaudio ];
    #   };
    # };
  };
}
