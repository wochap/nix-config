{ config, pkgs, lib, ... }:

let
  userName = config._userName;
in
{
  config = {
    environment.systemPackages = with pkgs; [
      direnv # auto run nix-shell
    ];

    services.lorri.enable = true;

    home-manager.users.${userName} = {
      home.file = {
        ".envrc".text = ''
          HOST_XDG_DATA_DIRS="''${XDG_DATA_DIRS:-}"
          eval "$(lorri direnv)"
          export XDG_DATA_DIRS="''${XDG_DATA_DIRS}:''${HOST_XDG_DATA_DIRS}"
        '';
        "shell.nix".text = ''
          let
            pkgs = import <nixpkgs> {};
          in pkgs.mkShell rec {
            name = "home";
            buildInputs = with pkgs; [
              python3
              nodePackages.http-server
              nodePackages.nodemon
              nodePackages.typescript
              nodePackages.typescript-language-server
              nodejs-14_x
              (yarn.override { nodejs = nodejs-14_x; })
            ];
          }
        '';
      };
    };
  };
}
