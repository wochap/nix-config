{ pkgs, ... }:

{
  config = {
    environment.systemPackages = with pkgs; [
      chntpw
      _custom.pythonPackages.bt-dualboot
    ];

    # Enable support for ntfs disks
    boot.supportedFilesystems = [ "ntfs" ];

    # Fix windows dualboot clock
    time.hardwareClockInLocalTime = true;
  };
}

