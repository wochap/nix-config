{ pkgs, ... }:

{
  animdl = pkgs.prevstable-python.callPackage ./animdl.nix {
    pkgs = pkgs.prevstable-python;
  };
  bt-dualboot = pkgs.prevstable-python.callPackage ./bt-dualboot.nix {
    pkgs = pkgs.prevstable-python;
  };
  hints = pkgs.prevstable-python.callPackage ./hints {
    pkgs = pkgs.prevstable-python;
  };
  python-remind = pkgs.prevstable-python.callPackage ./python-remind.nix {
    pkgs = pkgs.prevstable-python;
  };
  vidcutter = pkgs.prevstable-python.callPackage ./vidcutter.nix {
    pkgs = pkgs.prevstable-python;
  };
  pix2tex = pkgs.prevstable-python.callPackage ./pix2tex {
    pkgs = pkgs.prevstable-python;
  };
}

