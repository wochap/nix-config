{ ... }:

{
  config.boot = {
    loader = {
      grub.enable = false;
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 15;
      efi.canTouchEfiVariables = true;
    };

    tmp.cleanOnBoot = true;
  };
}
