{ config, pkgs, lib, ... }:

let
  phoneId = "04e8";
  android-repo = builtins.fetchTarball {
    url = https://github.com/tadfisher/android-nixpkgs/archive/0c4e5a01dbd4c8c894f2186a7c582abf55a43c5e.tar.gz;
    sha256 = "0x56nh4nxx5hvpi7aq66v7xm9mzn4b2gs50z60w8c3ciimjlpip8";
  };
  android-pkgs = (import "${android-repo}/default.nix") {
    channel = "stable";
  };
  android-hm = (import "${android-repo}/hm-module.nix");
  finalPackage = android-pkgs.sdk (sdk: with sdk; [
    build-tools-29-0-2
    build-tools-30-0-3
    cmdline-tools-latest
    emulator
    platform-tools
    platforms-android-29
  ]);
  path = "Android/Sdk";
in
{
  config = {
    programs.adb.enable = true;

    services.udev.extraRules = ''
      SUBSYSTEM=="usb", ATTR{idVendor}=="${phoneId}", MODE="0666", GROUP="plugdev"
    '';

    environment = {
      systemPackages = with pkgs; [
        jdk8
        jdk11
        android-studio
      ];
      sessionVariables = {
        # TODO: use android-studio jre path?
        JAVA_HOME = pkgs.jdk11.home;

        # Fix react native aapt2 errors
        GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${finalPackage}/share/android-sdk/build-tools/30.0.3/aapt2";
      };
    };

    home-manager.users.gean = {
      imports = [
        android-hm
      ];

      # TODO: use android hm options
      # Fine, I'll do it myself
      android-sdk.enable = false;
      android-sdk.finalPackage = finalPackage;
      home = {
        file.${path}.source = "${finalPackage}/share/android-sdk";
        packages = [ finalPackage ];
        sessionVariables = {
          ANDROID_HOME = "/home/gean/${path}";
          ANDROID_SDK_ROOT = "/home/gean/${path}";
        };
      };
    };
  };
}
