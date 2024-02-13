{ config, pkgs, lib, inputs, ... }:

let cfg = config._custom.programs.gaming;
in {
  imports = [ inputs.nix-gaming.nixosModules.pipewireLowLatency ];
  options._custom.programs.gaming.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      prevstable-gaming.lutris

      prevstable-gaming.protontricks

      # winetricks
      prevstable-gaming.winePackages.unstable
      prevstable-gaming.winetricks
      prevstable-gaming.wine64Packages.unstable
    ];

    # see https://github.com/fufexan/nix-gaming/#pipewire-low-latency
    services.pipewire.lowLatency.enable = true;
  };
}

