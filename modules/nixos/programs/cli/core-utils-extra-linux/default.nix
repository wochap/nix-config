{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.programs.core-utils-extra-linux;
in
{
  options._custom.programs.core-utils-extra-linux.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
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
