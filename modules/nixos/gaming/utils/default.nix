{ config, pkgs, lib, inputs, ... }:

let cfg = config._custom.gaming.utils;
in {
  imports = [ inputs.nix-gaming.nixosModules.pipewireLowLatency ];
  options._custom.gaming.utils.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      gamescope
      goverlay
      mangohud

      prevstable-gaming.protontricks
      protonup-qt

      # winetricks
      prevstable-gaming.winePackages.unstable
      prevstable-gaming.winetricks
      prevstable-gaming.wine64Packages.unstable
    ];

    # see https://github.com/fufexan/nix-gaming/#pipewire-low-latency
    services.pipewire.lowLatency.enable = true;

    programs.gamemode = {
      enable = true;
      settings.general.inhibit_screensaver = 0;
    };

    # TODO: add mangohud, gamescope
    hardware.opengl = {
      extraPackages = with pkgs; [ mangohud ];
      extraPackages32 = with pkgs; [ mangohud ];
    };
  };
}

