let pkgs = import <nixpkgs> { };
in pkgs.mkShell rec {
  name = "home";
  buildInputs = with pkgs; [
    python3
    nodePackages.gulp
    nodePackages.http-server
    nodePackages.nodemon
    nodejs-14_x
    (yarn.override { nodejs = nodejs-14_x; })
  ];
}

