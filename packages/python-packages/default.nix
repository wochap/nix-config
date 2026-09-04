{ pkgs, inputs, ... }:

{
  bt-dualboot = pkgs.prevstable-python.callPackage ./bt-dualboot.nix {
    pkgs = pkgs.prevstable-python;
  };
  bugwarrior = pkgs.prevstable-python.callPackage ./bugwarrior.nix {
    pkgs = pkgs.prevstable-python;
  };
  hints = pkgs.prevstable-python.callPackage ./hints {
    pkgs = pkgs.prevstable-python;
  };
  python-remind = pkgs.prevstable-python.callPackage ./python-remind.nix {
    pkgs = pkgs.prevstable-python;
    inherit inputs;
  };
}
