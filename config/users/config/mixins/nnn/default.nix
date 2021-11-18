{ config, pkgs, lib, ... }:

let
  userName = config._userName;
  nnn-repo = pkgs.fetchFromGitHub {
    owner = "jarun";
    repo = "nnn";
    rev = "aea97cf3a7e2f2cfd1ae607363c89be17b8e8dc7";
    sha256 = "1b9x7vqgpmyid9f0fklnjyrn9z9rqi2jbclp9v43cyz8iqh3w27x";
  };
in
{
  config = {
    environment = {
      systemPackages = with pkgs; [
        nnn # file manager CLI
      ];

      sessionVariables = {
        NNN_FIFO = "/tmp/nnn.fifo";
        NNN_PLUG = "p:preview-tui";
        SPLIT = "v";
        KITTY_LISTEN_ON = ''unix:''${TMPDIR-/tmp}/kitty'';
      };

      shellAliases = {
        f = "nnn";
      };
    };

    home-manager.users.${userName} = {
      xdg.configFile = {
        "nnn/plugins".source = "${nnn-repo}/plugins";
      };
    };
  };
}
