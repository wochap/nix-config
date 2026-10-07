{ pkgs, inputs, ... }:

{
  bt-dualboot = pkgs.prevstable-python.callPackage ./bt-dualboot.nix {
    pkgs = pkgs.prevstable-python;
  };
  python-remind = pkgs.prevstable-python.callPackage ./python-remind.nix {
    pkgs = pkgs.prevstable-python;
    inherit inputs;
  };
}
