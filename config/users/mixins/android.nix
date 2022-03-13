{ config, pkgs, lib, inputs, ... }:

let
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  phoneId = "04e8";
  path = "Android/Sdk";

  androidSdkPkg = pkgs.androidSdk (sdk:
    with sdk; [
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
in {
  config = {
    nixpkgs.overlays = [ inputs.android-nixpkgs.overlay ];

    programs.adb.enable = true;

    services.udev.extraRules = ''
      SUBSYSTEM=="usb", ATTR{idVendor}=="${phoneId}", MODE="0666", GROUP="plugdev"
    '';

    environment = {
      systemPackages = with pkgs; [ jdk8 jdk11 android-studio ];
      sessionVariables = {
        # TODO: use android-studio jre path?
        JAVA_HOME = pkgs.jdk11.home;

        # Fix react native aapt2 errors
        GRADLE_OPTS =
          "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdkPkg}/share/android-sdk/build-tools/30.0.3/aapt2";
      };
    };

    home-manager.users.${userName} = {
      # imports = [ android-hm ];
      imports = [ inputs.android-nixpkgs.hmModule ];

      config = {
        # TODO: use android hm options?
        android-sdk.enable = false;

        # Fine, I'll do it myself
        home = {
          file.${path}.source = "${androidSdkPkg}/share/android-sdk";
          packages = [ androidSdkPkg ];

          sessionVariables = {
            ANDROID_HOME = "/home/${userName}/${path}";
            ANDROID_SDK_ROOT = "/home/${userName}/${path}";
          };
        };

      };
    };
  };
}
