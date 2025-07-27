{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.gaming.utils;
  inherit (config._custom.globals) configDirectory;
in {
  imports = [ inputs.nix-gaming.nixosModules.pipewireLowLatency ];
  options._custom.gaming.utils.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      gamescope
      goverlay
      mangohud
      gamemode

      prevstable-gaming.protontricks
      protonup-qt

      # winetricks
      prevstable-gaming.winetricks
      prevstable-gaming.wineWowPackages.waylandFull

      bottles
    ];

    # see https://github.com/fufexan/nix-gaming/#pipewire-low-latency
    services.pipewire.lowLatency.enable = true;

    programs.gamemode = {
      enable = true;
      settings.general.inhibit_screensaver = 0;
    };

    # TODO: add mangohud, gamescope
    hardware.graphics = {
      extraPackages = with pkgs; [ mangohud ];
      extraPackages32 = with pkgs; [ mangohud ];
    };
    chaotic.mesa-git = {
      extraPackages = with pkgs; [ mangohud ];
      extraPackages32 = with pkgs; [ mangohud ];
    };

    _custom.hm = {
      xdg.configFile."MangoHud".source =
        lib._custom.relativeSymlink configDirectory ./dotfiles/MangoHud.conf;
    };
  };
}

