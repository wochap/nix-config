{ pkgs }:

{
  eww = pkgs.callPackage ./eww {};
  horizon-icons = pkgs.callPackage ./horizon-icons {};
  horizon-theme = pkgs.callPackage ./horizon-theme {};
  lightdm-webkit2-greeter = pkgs.callPackage ./lightdm-webkit2-greeter {};
  sddm-sugar-dark-greeter = pkgs.callPackage ./sddm-sugar-dark-greeter {};
  sddm-whitesur-greeter = pkgs.callPackage ./sddm-whitesur-greeter {};
  whitesur-dark-icons = pkgs.callPackage ./whitesur-dark-icons {};
  whitesur-dark-theme = pkgs.callPackage ./whitesur-dark-theme {};
  zscroll = pkgs.callPackage ./zscroll {};
}
