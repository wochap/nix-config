{ pkgs, lib }:

{
  bigsur-cursors = pkgs.callPackage ./bigsur-cursors {};
  dracula-icons = pkgs.callPackage ./dracula-icons {};
  horizon-icons = pkgs.callPackage ./horizon-icons {};
  horizon-theme = pkgs.callPackage ./horizon-theme {};
  interception-both-shift-capslock = pkgs.callPackage ./interception-both-shift-capslock {};
  interception-caps2esc = pkgs.callPackage ./interception-caps2esc {};
  libplist = pkgs.callPackage ./libplist.nix {};
  libplist2 = pkgs.callPackage ./libplist2.nix {};
  lightdm-webkit2-greeter = pkgs.callPackage ./lightdm-webkit2-greeter {};
  mailnotify = pkgs.callPackage ./mailnotify.nix {};
  mangadesk = pkgs.callPackage ./mangadesk.nix {};
  neeasade-wmutils-opt = pkgs.callPackage ./neeasade-wmutils-opt.nix {};
  nsxiv = pkgs.callPackage ./nsxiv.nix {};
  offlinemsmtp = pkgs.callPackage ./offlinemsmtp.nix {};
  ptsh = pkgs.callPackage ./ptsh {};
  sddm-sugar-dark-greeter = pkgs.callPackage ./sddm-sugar-dark-greeter {};
  sddm-whitesur-greeter = pkgs.callPackage ./sddm-whitesur-greeter {};
  sf-mono-liga-bin = pkgs.callPackage ./sf-mono-liga-bin.nix {};
  stremio = pkgs.qt5.callPackage ./stremio {};
  usbfluxd = pkgs.callPackage ./usbfluxd.nix {};
  way-displays = pkgs.callPackage ./way-displays { inherit pkgs; };
  whitesur-dark-icons = pkgs.callPackage ./whitesur-dark-icons {};
  whitesur-dark-theme = pkgs.callPackage ./whitesur-dark-theme {};
  zscroll = pkgs.callPackage ./zscroll {};
  customNodePackages = lib.dontRecurseIntoAttrs (pkgs.callPackage ./custom-node-packages {
    nodejs = pkgs.nodejs-14_x;
  });
}
