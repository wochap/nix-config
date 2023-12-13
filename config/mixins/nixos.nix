{ config, pkgs, lib, inputs, ... }:

let
  userName = config._userName;
  inherit (config._custom.globals) isHidpi;

  # Catppuccin mocha theme
  # colors extracted from kitty theme
  # you just need to change the first color (black)
  terminalColors = [
    "1E1E2E"
    "F38BA8"
    "A6E3A1"
    "F9E2AF"
    "89B4FA"
    "F5C2E7"
    "94E2D5"
    "BAC2DE"

    "585B70"
    "F38BA8"
    "A6E3A1"
    "F9E2AF"
    "89B4FA"
    "F5C2E7"
    "94E2D5"
    "A6ADC8"
  ];
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
      colors = terminalColors;
      font = if isHidpi then "ter-132n" else "Lat2-Terminus16";
      earlySetup = true;
      keyMap = "us";
      packages = [ pkgs.terminus_font ];
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

    # Apply trim to SSDs
    services.fstrim.enable = lib.mkDefault true;

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
