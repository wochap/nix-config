{ pkgs }:

{
  eww = pkgs.callPackage ./eww {};
  horizon-icons = pkgs.callPackage ./horizon-icons {};
  horizon-theme = pkgs.callPackage ./horizon-theme {};
  whitesur-dark-theme = pkgs.callPackage ./whitesur-dark-theme {};
  whitesur-dark-icons = pkgs.callPackage ./whitesur-dark-icons {};
  zscroll = pkgs.callPackage ./zscroll {};
  lightdm-webkit2-greeter = pkgs.callPackage ./lightdm-webkit2-greeter {};
}
