{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.services.android;

  phoneId = "04e8";

  buildToolsVersion = "36.0.0";
  androidComposition = (pkgs.androidenv.override { licenseAccepted = true; }).composeAndroidPackages {
    platformVersions = [
      "36"
      "37"
    ];
    buildToolsVersions = [
      buildToolsVersion
      "37.0.0"
    ];
    includeEmulator = true;
    includeSystemImages = true;
    systemImageTypes = [ "google_apis_playstore" ];
    abiVersions = [ "x86_64" ];
    includeSources = false;
  };
  androidSdk = androidComposition.androidsdk;
  sdkRoot = "${androidSdk}/libexec/android-sdk";

  android-studio = pkgs.androidStudioPackages.stable.withSdk androidSdk;
in
{
  options._custom.services.android = {
    enable = lib.mkEnableOption { };
    enableSdk = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        # Enable android device debugging
        # NOTE: systemd 258 handles adb uaccess rules, adbusers group no longer exists
        environment.systemPackages = [ pkgs.android-tools ];
        services.udev.extraRules = ''
          SUBSYSTEM=="usb", ATTR{idVendor}=="${phoneId}", MODE="0666", TAG+="uaccess"
        '';
      }

      (lib.mkIf cfg.enableSdk {
        # Required by android emulator (/dev/kvm)
        _custom.user.extraGroups = [ "kvm" ];

        _custom.hm.home = {
          packages = [
            android-studio
            androidSdk
            pkgs.jdk21
          ];

          sessionVariables = {
            # Required by android-studio on wm
            _JAVA_AWT_WM_NONREPARENTING = "1";

            JAVA_HOME = pkgs.jdk21.home;
            ANDROID_HOME = sdkRoot;
            ANDROID_SDK_ROOT = sdkRoot;

            # Use nix aapt2 instead of the dynamically linked one gradle downloads from maven
            GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${sdkRoot}/build-tools/${buildToolsVersion}/aapt2";
          };
        };
      })
    ]
  );
}
