{ config, pkgs, lib, inputs, ... }:

let
  isWayland = config._displayServer == "wayland";
  extraArgs = if isWayland then "--cmd sway" else "";
in {
  config = {
    services.xserver.displayManager.lightdm.enable = lib.mkForce false;

    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time ${extraArgs}";
          user = "greeter";
        };
      };
    };

  };
}
