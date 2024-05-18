{ config, lib, inputs, ... }:

let inherit (config._custom.globals) themeColors;
in {
  config.boot = {
    loader = {
      grub = {
        enable = false;
        configurationLimit = 10;
        device = "nodev";
        efiSupport = true;
        enableCryptodisk = true;
        theme = lib.mkDefault
          "${inputs.catppuccin-grub}/src/catppuccin-${themeColors.flavor}-grub-theme";
        useOSProber = true;
      };

      systemd-boot = {
        enable = lib.mkDefault true;
        configurationLimit = 10;
        consoleMode = "keep";
      };

      efi.canTouchEfiVariables = true;
    };

    # increase the limits to avoid running out of inotify watches
    kernel.sysctl."fs.inotify.max_user_watches" = "1048576";

    tmp.cleanOnBoot = true;
  };
}
