{ config, pkgs, lib, inputs, ... }:

let cfg = config._custom.wm.audio;
in {
  options._custom.wm.audio = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
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
