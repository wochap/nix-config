{ config, pkgs, lib, ... }:

let
  isDarwin = config._displayServer == "darwin";
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
      sessionVariables = {
        NNN_TRASH = "1";
        NNN_FIFO = "/tmp/nnn.fifo";
        SPLIT = "v";
        KITTY_LISTEN_ON = ''unix:''${TMPDIR-/tmp}/kitty'';
      };
      shellAliases = {
        f = "nnn";
      };
    };

    home-manager.users.${userName} = {
      programs.nnn = {
        enable = true;
        package = pkgs.nnn.override ({
          withNerdIcons = true;
        });
        extraPackages = with pkgs; [
          mediainfo
        ] ++ lib.optionals (!isDarwin) [
          ffmpegthumbnailer
          sxiv
        ];
        plugins = {
          mappings = {
            p = "preview-tui";
          };
          src = "${nnn-repo}/plugins";
        };
      };
    };
  };
}
