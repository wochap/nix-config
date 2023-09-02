{ pkgs, lib }:

{
  advcpmv = pkgs.callPackage ./advcpmv {};
  interception-both-shift-capslock = pkgs.callPackage ./interception-both-shift-capslock {};
  mailnotify = pkgs.callPackage ./mailnotify.nix {};
  mangadesk = pkgs.callPackage ./mangadesk.nix {};
  nwg-look = pkgs.callPackage ./nwg-look {};
  offlinemsmtp = pkgs.callPackage ./offlinemsmtp.nix {};
  ptsh = pkgs.callPackage ./ptsh {};
  sf-mono-liga-bin = pkgs.callPackage ./sf-mono-liga-bin.nix {};
  stremio = pkgs.qt5.callPackage ./stremio {};
  usbfluxd = pkgs.callPackage ./usbfluxd.nix {};
  customNodePackages = lib.dontRecurseIntoAttrs (pkgs.callPackage ./custom-node-packages {
    nodejs = pkgs.prevstable-nodejs.nodejs-14_x;
  });
}
