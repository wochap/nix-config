{ config, pkgs, lib, ... }:
let
  hostName = "vivobook";
  userName = "franshesca";
in
{
  imports = [
    # Include the results of the hardware scan.
    /etc/nixos/hardware-configuration.nix
    # Cachix required by doom-emacs
    # /etc/nixos/cachix.nix

    /config/wayland.nix
  ];

  config = {
    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "21.05"; # Did you read the comment?

    # This value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    # changes in each release.
    home-manager.users.${userName}.home.stateVersion = "21.03";

    boot = {
      loader = {
        grub.enable = false;
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };
      cleanTmpDir = true;
    };

    networking = {
      hostName = hostName;

      # The global useDHCP flag is deprecated, therefore explicitly set to false here.
      # Per-interface useDHCP will be mandatory in the future, so this generated config
      # replicates the default behaviour.
      useDHCP = false;
      interfaces.wlp1s0.useDHCP = true;
    };

    # Fix windows dualboot clock
    time.hardwareClockInLocalTime = true;

    services.xserver = {
      libinput.enable = true;

      # Setup keyboard
      layout = "latam";
      xkbModel = "pc104";
      # xkbVariant = "altgr-intl";
    };
  };
}
