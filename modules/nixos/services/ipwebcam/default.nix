{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.services.ipwebcam;

  run-videochat = pkgs.writeScriptBin "run-videochat"
    (builtins.replaceStrings [ "#!/bin/bash" ] [ "#!/usr/bin/env bash" ]
      (builtins.readFile "${inputs.ipwebcam-gst}/run-videochat.sh"));
in {
  options._custom.services.ipwebcam.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    boot = {
      extraModprobeConfig = ''
        options v4l2loopback devices=1 exclusive_caps=1 video_nr=99
      '';
      kernelModules = [ "v4l2loopback" ];
      extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
    };

    environment.systemPackages = with pkgs; [
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-good
      gst_all_1.gstreamer
      gst_all_1.gstreamer.dev
      v4l-utils

      droidcam

      # required by run-videochat
      gnome.zenity
      run-videochat
    ];

    _custom.hm = {
      programs.obs-studio.plugins = with pkgs;
        [ obs-studio-plugins.droidcam-obs ];
    };
  };
}
