{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:

let
  cfg = config._custom.desktop.audio;
in
{
  options._custom.desktop.audio = {
    enable = lib.mkEnableOption { };
    enableEasyeffects = lib.mkEnableOption { };
    enableNoisetorch = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        nixpkgs-unstable.wiremix
        pwvucontrol # pavucontrol like, pipewire gui
      ];

      shellAliases.atui = "wiremix";
    };

    services.pulseaudio.enable = false;

    # suppress background noice
    programs.noisetorch.enable = cfg.enableNoisetorch;

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

    _custom.hm = lib.mkIf cfg.enableEasyeffects {
      # alternative to Dolby Atmos
      services.easyeffects = {
        enable = true;
        preset = "Perfect EQ";
      };
      xdg.configFile = lib._custom.linkContents "easyeffects/output" "${inputs.easy-effects-presets}";

      # this fixes glitches in my audio
      systemd.user.services.pipewire-force-quantum = {
        Unit = {
          Description = "Force PipeWire quantum size to 512";
          After = [ "pipewire.service" ];
          PartOf = [ "pipewire.service" ];
        };
        Install.WantedBy = [ "pipewire.service" ];
        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.pipewire}/bin/pw-metadata -n settings 0 clock.force-quantum 512";
          RemainAfterExit = true;
        };
      };
    };
  };
}
