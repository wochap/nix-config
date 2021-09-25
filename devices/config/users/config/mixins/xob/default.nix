{ config, pkgs, lib, ... }:

let
  userName = config._userName;
  xob = pkgs.xob.overrideAttrs(o: {
    src = pkgs.fetchFromGitHub {
      owner = "florentc";
      repo = "xob";
      rev = "dc9079022fe3f70118f0f802011d0694c8a650d8";
      sha256 = "1x4aafiyd9k4y8cmvn7rgfif3g5s5hhlbj5nz71qsyqg21nn7hrw";
    };
    makeFlags = [
      "prefix=$(out)"
      "enable_alpha=yes"
    ];
    buildInputs = with pkgs; [
      xorg.libX11
      xorg.libXrender
      libconfig
    ];
  });
in
{
  config = {
    environment = {
      systemPackages = [
        xob
      ];
      etc = {
        "scripts/volume.py" = {
          source = ./scripts/volume.py;
          mode = "0755";
        };
      };
    };

    home-manager.users.${userName} = {
      home.file = {
        ".config/xob/styles.cfg".source = ./dotfiles/styles.cfg;
      };
    };
  };
}
