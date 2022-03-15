{ config, pkgs, lib, ... }:

let userName = config._userName;
in {
  config = {
    home-manager.users.${userName} = {
      home = {
        packages = with pkgs; [ exa ];

        shellAliases = {
          ls = "exa --icons --group-directories-first --across";
          la = "exa --icons --group-directories-first --all --long";
        };
      };
    };
  };
}
