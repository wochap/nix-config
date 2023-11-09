{ pkgs, lib, ... }:

let
  localPkgs = {
    unwrapHex = str: builtins.substring 1 (builtins.stringLength str) str;

    advcpmv = pkgs.callPackage ./advcpmv { };
    dunst-nctui = pkgs.callPackage ./dunst-nctui.nix { };
    dwl-state = pkgs.callPackage ./dwl-state.nix { };
    fromYAML = pkgs.callPackage ./from-yaml.nix { };
    interception-both-shift-capslock =
      pkgs.callPackage ./interception-both-shift-capslock { };
    mailnotify = pkgs.callPackage ./mailnotify.nix { };
    mangadesk = pkgs.callPackage ./mangadesk.nix { };
    nwg-look = pkgs.callPackage ./nwg-look { };
    offlinemsmtp = pkgs.callPackage ./offlinemsmtp.nix { };
    ptsh = pkgs.callPackage ./ptsh { };
    sf-mono-liga-bin = pkgs.callPackage ./sf-mono-liga-bin.nix { };
    tela-icon-theme = pkgs.callPackage ./tela-icon-theme { };
    usbfluxd = pkgs.callPackage ./usbfluxd.nix { };
    customNodePackages = lib.dontRecurseIntoAttrs
      (pkgs.callPackage ./custom-node-packages {
        nodejs = pkgs.prevstable-nodejs.nodejs-14_x;
      });
  };
in {
  config = { nixpkgs.overlays = [ (final: prev: { _custom = localPkgs; }) ]; };
}
