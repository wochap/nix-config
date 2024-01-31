{ ... }:

{
  config.boot = {
    loader = {
      grub.enable = false;
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 30;
      efi.canTouchEfiVariables = true;
    };

    tmp.cleanOnBoot = true;
  };
}
