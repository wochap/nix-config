{ config, pkgs, lib, inputs, system, ... }:

let
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};

  phoneId = "04e8";
  path = "Android/Sdk";

  android-studio-stable = pkgs.androidStudioPackages.stable;
  android-sdk = inputs.android-nixpkgs.sdk.${system} (sdkPkgs:
    with sdkPkgs; [
      # Required by React Native
      build-tools-29-0-3
      build-tools-30-0-3
      cmdline-tools-latest
      emulator
      platform-tools
      platforms-android-29
      platforms-android-30

      # Required by android emulator
      sources-android-30
      system-images-android-30-google-apis-playstore-x86-64
      system-images-android-30-google-apis-x86-64
    ]);
in {
  config = {
    # nixpkgs.overlays = [ inputs.android-nixpkgs.overlay ];

    programs.adb.enable = true;

    services.udev.extraRules = ''
      SUBSYSTEM=="usb", ATTR{idVendor}=="${phoneId}", MODE="0666", GROUP="plugdev"
    '';

    environment = {
      systemPackages = with pkgs; [
        jdk11
        gradle
        android-sdk
        android-studio-stable
      ];
      variables = { _JAVA_AWT_WM_NONREPARENTING = "1"; };
      sessionVariables = {
        JAVA_HOME = pkgs.jdk11.home;
        ANDROID_HOME = "${android-sdk}/share/android-sdk";
        ANDROID_SDK_ROOT = "${android-sdk}/share/android-sdk";

        # Fix react native aapt2 errors
        GRADLE_OPTS =
          "-Dorg.gradle.project.android.aapt2FromMavenOverride=${android-sdk}/share/android-sdk/build-tools/30.0.3/aapt2";
      };
    };

    home-manager.users.${userName} = {
      # imports = [ android-hm ];
      # imports = [ inputs.android-nixpkgs.hmModule ];

      config = {
        # TODO: use android hm options?
        # android-sdk.enable = false;

        # Fine, I'll do it myself
        home = {
          # file.${path}.source = "${androidSdkPkg}/share/android-sdk";
          # packages = [ androidSdkPkg ];

          sessionVariables = {
            # ANDROID_HOME = "/home/${userName}/${path}";
            # ANDROID_SDK_ROOT = "/home/${userName}/${path}";
          };
        };

      };
    };
  };
}
