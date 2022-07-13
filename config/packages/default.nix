{ pkgs, lib }:

{
  dracula-icons = pkgs.callPackage ./dracula-icons {};
  interception-both-shift-capslock = pkgs.callPackage ./interception-both-shift-capslock {};
  interception-caps2esc = pkgs.callPackage ./interception-caps2esc {};
  mailnotify = pkgs.callPackage ./mailnotify {};
  mangadesk = pkgs.callPackage ./mangadesk.nix {};
  neeasade-wmutils-opt = pkgs.callPackage ./neeasade-wmutils-opt.nix {};
  nsxiv = pkgs.callPackage ./nsxiv.nix {};
  offlinemsmtp = pkgs.callPackage ./offlinemsmtp.nix {};
  ptsh = pkgs.callPackage ./ptsh {};
  sf-mono-liga-bin = pkgs.callPackage ./sf-mono-liga-bin.nix {};
  stremio = pkgs.qt5.callPackage ./stremio {};
  usbfluxd = pkgs.callPackage ./usbfluxd.nix {};
  way-displays = pkgs.callPackage ./way-displays { inherit pkgs; };
  zscroll = pkgs.callPackage ./zscroll {};
  customNodePackages = lib.dontRecurseIntoAttrs (pkgs.callPackage ./custom-node-packages {
    nodejs = pkgs.nodejs-14_x;
  });
}
