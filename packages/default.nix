{
  inputs,
  pkgs,
  lib,
  ...
}:

let
  customPkgs = rec {
    tmuxinator = pkgs.callPackage ./tmuxinator { };
    fcitx5-fbterm = pkgs.callPackage ./fcitx5-fbterm { };
    clipboard-sync = pkgs.callPackage ./clipboard-sync { };
    advcpmv = pkgs.callPackage ./advcpmv { };
    generate-ssc = pkgs.callPackage ./generate-ssc { };
    gh-prx = pkgs.callPackage ./gh-prx { };
    wochap-ssc = generate-ssc {
      domain = "wochap.local";
      # NOTE: don't use 127.0.0.1 to prevent conflicts with localhost
      address = "127.0.1.1";
    };
    interception-both-shift-capslock = pkgs.callPackage ./interception-both-shift-capslock { };
    mailnotify = pkgs.callPackage ./mailnotify { };
    offlinemsmtp = inputs.offlinemsmtp.packages.${pkgs.system}.default;
    greetd-autologin = pkgs.callPackage ./greetd-autologin { };
    run-desktop = pkgs.callPackage ./run-desktop { };
    ptsh = pkgs.callPackage ./ptsh { };
    tela-icon-theme = pkgs.callPackage ./tela-icon-theme { };
    usbfluxd = pkgs.callPackage ./usbfluxd { };
    supertonic = pkgs.callPackage ./supertonic { };
    shotclip = pkgs.callPackage ./shotclip { inherit inputs; };
    rtk = pkgs.callPackage ./rtk { };
    pythonPackages = lib.dontRecurseIntoAttrs (pkgs.callPackage ./python-packages { inherit inputs; });
  };
in
{
  config = {
    nixpkgs.overlays = [ (final: prev: { _custom = customPkgs; }) ];
  };
}
