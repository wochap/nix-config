{ config, pkgs, lib, ... }:

let cfg = config._custom.programs.vscode;
in {
  options._custom.programs.vscode.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home = {
        packages = with pkgs; [
          trash-cli

          (vscode.fhsWithPackages
            (ps: with ps; [ rustup zlib openssl.dev pkg-config ]))
        ];
        sessionVariables = {
          # Fix vscode delete
          ELECTRON_TRASH = "trash-cli";
        };
      };
    };
  };
}
