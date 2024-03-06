{ pkgs, ... }:

{
  animdl = pkgs.prevstable-python.callPackage ./animdl.nix {
    pkgs = pkgs.prevstable-python;
  };
  python-remind = pkgs.prevstable-python.callPackage ./python-remind.nix {
    pkgs = pkgs.prevstable-python;
  };
  vidcutter = pkgs.prevstable-python.callPackage ./vidcutter.nix {
    pkgs = pkgs.prevstable-python;
  };
}

