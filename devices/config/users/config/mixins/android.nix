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
        android-studio
      ];
      sessionVariables = {
        JAVA_HOME = pkgs.jdk8.home;
        # GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/30.0.3/aapt2";
      };
    };

    home-manager.users.gean = {
      imports = [
        android-hm
      ];

      android-sdk = {
        enable = false;
        path = "/home/gean/.local/share/android";
        packages = android-pkgs.sdk (sdk: with sdk; [
          android.build-tools-29-0-2
          android.build-tools-30-0-3
          android.cmdline-tools-latest
          android.emulator
          android.platform-tools
          android.platforms-android-29
        ]);
      };
    };
  };
}
