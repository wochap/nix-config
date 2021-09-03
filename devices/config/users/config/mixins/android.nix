{ config, pkgs, lib, ... }:

let
  phoneId = "04e8";
  android-repo = builtins.fetchTarball {
    url = https://github.com/tadfisher/android-nixpkgs/archive/14306de794ed518c548d20c9c16dbe12a305b9e6.tar.gz;
    sha256 = "10rvcm8yhz0c4y5hr3di5i5bbhjclb63r77sm1bdhg67ri9zzj4j";
  };
  android-pkgs = (import "${android-repo}/default.nix") {
    channel = "stable";
  };
  android-hm = (import "${android-repo}/hm-module.nix");
  finalPackage = android-pkgs.sdk (sdk: with sdk; [
    # Required by react-native/flutter
    build-tools-29-0-2
    build-tools-30-0-3
    cmdline-tools-latest
    emulator
    platform-tools
    platforms-android-29

    # Required to create emulator
    build-tools-31-0-0
    platforms-android-30
    platforms-android-31
    sources-android-30
    system-images-android-30-google-apis-playstore-x86
    system-images-android-30-google-apis-x86
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
