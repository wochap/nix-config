{ config, lib, ... }:

let cfg = config._custom.de.audio;
in {
  options._custom.de.audio.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.user.extraGroups = [ "audio" ];

    hardware.pulseaudio.enable = false;

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

    # I copy the following from other user config
    # systemd.user.services = {
    #   pipewire-pulse = {
    #     path = [ pkgs.pulseaudio ];
    #   };
    # };
  };
}
