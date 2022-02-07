{ pkgs, lib }:

{
  interception-both-shift-capslock = pkgs.callPackage ./interception-both-shift-capslock {};
  interception-caps2esc = pkgs.callPackage ./interception-caps2esc {};
  way-displays = pkgs.callPackage ./way-displays { inherit pkgs; };
  bigsur-cursors = pkgs.callPackage ./bigsur-cursors {};
  dracula-icons = pkgs.callPackage ./dracula-icons {};
  horizon-icons = pkgs.callPackage ./horizon-icons {};
  horizon-theme = pkgs.callPackage ./horizon-theme {};
  lightdm-webkit2-greeter = pkgs.callPackage ./lightdm-webkit2-greeter {};
  ptsh = pkgs.callPackage ./ptsh {};
  sddm-sugar-dark-greeter = pkgs.callPackage ./sddm-sugar-dark-greeter {};
  sddm-whitesur-greeter = pkgs.callPackage ./sddm-whitesur-greeter {};
  stremio = pkgs.qt5.callPackage ./stremio {};
  whitesur-dark-icons = pkgs.callPackage ./whitesur-dark-icons {};
  whitesur-dark-theme = pkgs.callPackage ./whitesur-dark-theme {};
  zscroll = pkgs.callPackage ./zscroll {};
  customNodePackages = lib.dontRecurseIntoAttrs (pkgs.callPackage ./custom-node-packages {
    nodejs = pkgs.nodejs-14_x;
  });
}
