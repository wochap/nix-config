{ pkgs }:

{
  horizon-theme = pkgs.callPackage ./horizon-theme {};
  horizon-icons = pkgs.callPackage ./horizon-icons {};
}
