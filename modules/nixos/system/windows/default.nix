{ ... }:

{
  config = {
    # Enable support for ntfs disks
    boot.supportedFilesystems = [ "ntfs" ];

    # Fix windows dualboot clock
    time.hardwareClockInLocalTime = true;
  };
}

