{ config, pkgs, lib, inputs, ... }:

let userName = config._userName;
in {
  imports = [
    # Install home manager
    inputs.home-manager.nixosModules.home-manager

    # Install nur
    inputs.nur.nixosModules.nur
  ];

  config = {
    boot = {
      # Bootloader
      loader = {
        grub.enable = false;
        systemd-boot.enable = true;
        systemd-boot.configurationLimit = 42;
        efi.canTouchEfiVariables = true;
      };

      tmp.cleanOnBoot = true;

      # Enable support for ntfs disks
      supportedFilesystems = [ "ntfs" ];
    };

    systemd.extraConfig = ''
      DefaultTimeoutStopSec=15s
    '';

    # Select internationalisation properties.
    i18n.defaultLocale = "en_US.UTF-8";

    console = {
      earlySetup = true;
      keyMap = "us";
    };

    security.sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };

    hardware.opengl.enable = true;

    services.xserver = {
      enable = true;
      exportConfiguration = true;
    };

    # minimum amount of swapping without disabling it entirely
    boot.kernel.sysctl = { "vm.swappiness" = lib.mkDefault 1; };

    documentation.man.generateCaches = true;
    documentation.dev.enable = true;

    # Shell integration for VTE terminals
    # Required for some gtk apps
    programs.bash.vteIntegration = lib.mkDefault true;
    programs.zsh.vteIntegration = lib.mkDefault true;

    # create user
    users.users.${userName} = {
      hashedPassword =
        "$6$rvioLchC4DiAN732$Me4ZmdCxRy3bacz/eGfyruh5sVVY2wK5dorX1ALUs2usXMKCIOQJYoGZ/qKSlzqbTAu3QHh6OpgMYgQgK92vn.";
      isNormalUser = true;
      isSystemUser = false;
      extraGroups =
        [ "audio" "disk" "input" "networkmanager" "storage" "video" "wheel" ];
    };

    home-manager.users.${userName} = {
      # better ls sorting
      home.language.collate = "C.UTF-8";
    };
  };
}
