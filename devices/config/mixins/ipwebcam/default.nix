{ config, pkgs, lib, ... }:

let
  run-videochat = pkgs.writeScriptBin "run-videochat" (builtins.readFile ./scripts/run-videochat.sh);
in
{
  config = {
    boot = {
      extraModprobeConfig = ''
        options v4l2loopback devices=1 exclusive_caps=1
      '';
      kernelModules = [
        "v4l2loopback"
      ];
      extraModulePackages = [
        config.boot.kernelPackages.v4l2loopback
      ];
    };

    environment.systemPackages = with pkgs; [
      gnome3.zenity
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-good
      gst_all_1.gstreamer
      gst_all_1.gstreamer.dev
      run-videochat
      v4l-utils
    ];
  };
}
