{ config, pkgs, lib, inputs, system, ... }:

let
userName = config._userName;
hmConfig = config.home-manager.users.${userName};

android-sdk-home-path = "Android/Sdk";
phoneId = "04e8";

android-studio-stable = pkgs.androidStudioPackages.stable;
android-sdk = inputs.android-nixpkgs.sdk.${system} (sdkPkgs:
    with sdkPkgs; [
    cmdline-tools-latest
    emulator
    platform-tools

# Android 30
    build-tools-30-0-2
    platforms-android-30

# Required by android emulator
    sources-android-30
    system-images-android-30-google-apis-playstore-x86
    system-images-android-30-google-apis-x86

# Android 29
# build-tools-29-0-3
# platforms-android-29
# sources-android-29
# system-images-android-29-google-apis-playstore-x86-64
# system-images-android-29-google-apis-x86-64
    ]);
    in {
      config = {
# Enable android device debugging
        programs.adb.enable = true;
        services.udev.extraRules = ''
          SUBSYSTEM=="usb", ATTR{idVendor}=="${phoneId}", MODE="0666", GROUP="plugdev"
          '';

        home-manager.users.${userName} = {
          config = {
            home = {
              file.${android-sdk-home-path}.source =
                "${android-sdk}/share/android-sdk";

              packages = with pkgs; [
                android-sdk
                  android-studio-stable
                  gradle
                  jdk11
              ];

              sessionVariables = {
# Required by android-studio on wm
                _JAVA_AWT_WM_NONREPARENTING = "1";

                JAVA_HOME = pkgs.jdk11.home;
                ANDROID_HOME = "/home/${userName}/${android-sdk-home-path}";
                ANDROID_SDK_ROOT = "/home/${userName}/${android-sdk-home-path}";

# Fix react-native aapt2 errors
                GRADLE_OPTS =
                  "-Dorg.gradle.project.android.aapt2FromMavenOverride=${android-sdk}/share/android-sdk/build-tools/30.0.2/aapt2";
              };
            };

          };
        };
      };
    }

