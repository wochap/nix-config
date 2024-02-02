{ pkgs, lib, ... }:

let
  localPkgs = rec {
    advcpmv = pkgs.callPackage ./advcpmv { };
    dunst-nctui = pkgs.callPackage ./dunst-nctui { };
    dwl-state = pkgs.callPackage ./dwl-state { };
    generate-ssc = pkgs.callPackage ./generate-ssc { };
    generated-ssc = generate-ssc { domain = "wochap.local"; };
    interception-both-shift-capslock =
      pkgs.callPackage ./interception-both-shift-capslock { };
    mailnotify = pkgs.callPackage ./mailnotify { };
    mangadesk = pkgs.callPackage ./mangadesk { };
    matcha = pkgs.callPackage ./matcha { };
    offlinemsmtp = pkgs.callPackage ./offlinemsmtp { };
    ollama-webui = pkgs.callPackage ./ollama-webui { };
    ptsh = pkgs.callPackage ./ptsh { };
    tela-icon-theme = pkgs.callPackage ./tela-icon-theme { };
    usbfluxd = pkgs.callPackage ./usbfluxd { };
    nodePackages = lib.dontRecurseIntoAttrs
      (pkgs.callPackage ./custom-node-packages {
        nodejs = pkgs.prevstable-nodejs.nodejs_20;
      });
  };
in {
  config = { nixpkgs.overlays = [ (final: prev: { _custom = localPkgs; }) ]; };
}
