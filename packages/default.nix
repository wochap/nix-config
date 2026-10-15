# Overlay that exposes this repo's packages as `pkgs._custom.*`.
# Exported as `overlays.default` and applied by ../overlays.
{ inputs }:

final: prev:

let
  inherit (final) lib;
  system = final.stdenv.hostPlatform.system;
in
{
  _custom = rec {
    tmuxinator = final.callPackage ./tmuxinator { };
    fcitx5-fbterm = final.callPackage ./fcitx5-fbterm { };
    clipboard-sync = final.callPackage ./clipboard-sync { };
    advcpmv = final.callPackage ./advcpmv { };
    generate-ssc = final.callPackage ./generate-ssc { };
    gh-prx = final.callPackage ./gh-prx { };
    wochap-ssc = generate-ssc {
      domain = "wochap.local";
      # NOTE: don't use 127.0.0.1 to prevent conflicts with localhost
      address = "127.0.1.1";
    };
    interception-both-shift-capslock = final.callPackage ./interception-both-shift-capslock { };
    mailnotify = final.callPackage ./mailnotify { };
    offlinemsmtp = inputs.offlinemsmtp.packages.${system}.default;
    greetd-autologin = final.callPackage ./greetd-autologin { };
    run-desktop = final.callPackage ./run-desktop { };
    ptsh = final.callPackage ./ptsh { };
    tela-icon-theme = final.callPackage ./tela-icon-theme { };
    usbfluxd = final.callPackage ./usbfluxd { };
    supertonic = final.callPackage ./supertonic { };
    rapidocr = final.callPackage ./rapidocr { };
    shotclip = final.callPackage ./shotclip { inherit inputs; };
    rtk = final.callPackage ./rtk { inherit inputs; };
    shell-auth = final.callPackage ./shell-auth { };
    libfprint-fpcmoh = final.callPackage ./libfprint-fpcmoh { };
    openspec-pipeline = final.callPackage ./openspec-pipeline { inherit agents; };
    agents = final.callPackage ./agents { };
    pythonPackages = lib.dontRecurseIntoAttrs (
      final.callPackage ./python-packages { inherit inputs; }
    );
  };
}
