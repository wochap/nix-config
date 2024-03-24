{ pkgs, ... }:

{
  config = {
    environment.systemPackages = with pkgs;
      [ _custom.pythonPackages.bt-dualboot ];

    # Enable support for ntfs disks
    boot.supportedFilesystems = [ "ntfs" ];

    # Fix windows dualboot clock
    time.hardwareClockInLocalTime = true;
  };
}

