let
  pkgs = import <nixpkgs> {};
in pkgs.mkShell rec {
  name = "nix-config";
  buildInputs = with pkgs; [
    python3
  ];
}
