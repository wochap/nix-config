{ config, lib, inputs, pkgs, ... }:

let cfg = config._custom.desktop.audio;
in {
  options._custom.desktop.audio.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.user.extraGroups = [ "audio" ];

    environment.systemPackages = with pkgs; [
      pulseaudio
      pulsemixer # pulseaudio
      nixpkgs-unstable.wiremix
      # pavucontrol # pulseaudio gui
      pwvucontrol # pipewire gui
    ];

    services.pulseaudio.enable = false;

    hardware.enableAllFirmware = true;

    # suppress background noice
    programs.noisetorch.enable = true;

    # Enable audio
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      # TODO: disable pulse
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
      xdg.configFile = lib._custom.linkContents "easyeffects/output"
        "${inputs.easy-effects-presets}";
    };
  };
}
