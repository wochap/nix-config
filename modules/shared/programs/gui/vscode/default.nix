{ config, pkgs, lib, ... }:

let cfg = config._custom.programs.vscode;
in {
  options._custom.programs.vscode.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs;
        [
          (vscode.fhsWithPackages
            (ps: with ps; [ rustup zlib openssl.dev pkg-config ]))
        ];

      programs.git.ignores = [ ".vscode" ];
    };
  };
}
