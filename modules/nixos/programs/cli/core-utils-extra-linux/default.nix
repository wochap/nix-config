{ config, pkgs, lib, ... }:

let cfg = config._custom.programs.core-utils-extra-linux;
in {
  options._custom.programs.core-utils-extra-linux.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        heimdall = prev.heimdall.overrideAttrs (_: {
          version = "02b577ec774f2ce66bcb4cf96cf15d8d3d4c7720";
          src = prev.fetchFromSourcehut {
            owner = "~grimler";
            repo = "Heimdall";
            rev = "02b577ec774f2ce66bcb4cf96cf15d8d3d4c7720";
            sha256 = "sha256-tcAE83CEHXCvHSn/S9pWu6pUiqGmukMifEadqPDTkQ0=";
          };
        });
      })
    ];

    environment.systemPackages = with pkgs; [
      tor
      w3m-full
      libwebp
      devour # xorg window swallower
      ifuse # mount ios
      libimobiledevice # mount ios
      nmap
      slop # xorg region selection
      tty-clock # clock
      usbutils # lsusb, for android development
      # heimdall # reset samsung ROM
      # metasploit
      # tightvnc
    ];

    _custom.hm = {
      home.shellAliases.ttc = ''tty-clock -c -C 2 -r -f "%A, %B %d"'';
    };
  };
}

