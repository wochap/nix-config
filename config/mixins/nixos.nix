{ config, pkgs, lib, inputs, ... }:

let
  isHidpi = config._isHidpi;
  isMbp = config.networking.hostName == "gmbp";
in {
  imports = [
    # Install home manager
    inputs.home-manager.nixosModules.home-manager
  ];

  config = {
    environment = { shellAliases = { open = "xdg-open"; }; };

    boot = {
      loader = {
        grub.configurationLimit = 42;
        grub.efiSupport = true;
        grub.useOSProber = true;
        systemd-boot.configurationLimit = 42;
      };

      # Enable ntfs disks
      supportedFilesystems = [ "ntfs" ];
    };

    systemd.extraConfig = ''
      DefaultTimeoutStopSec=25s
    '';

    # Select internationalisation properties.
    i18n.defaultLocale = "en_US.UTF-8";

    console = {
      font = if isHidpi then "ter-132n" else "Lat2-Terminus16";
      earlySetup = true;
      keyMap = "us";
      packages = [ pkgs.terminus_font ];
    };

    # Clear nixos store
    # nix.settings.auto-optimise-store = true;

    security.sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };

    hardware.video.hidpi.enable = true;

    # Enable bluetooth
    hardware.bluetooth.enable = true;

    # Enable OpenGL
    hardware.opengl.enable = true;
    hardware.opengl.driSupport = !isMbp;

    hardware.opengl.driSupport32Bit = !isMbp;

    # Enable audio
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      # If you want to use JACK applications, uncomment this
      #jack.enable = true;

      wireplumber.enable = true;
      media-session.enable = false;
    };

    services.xserver = {
      enable = true;
      exportConfiguration = true;
    };

    # Apply trim to SSDs
    services.fstrim.enable = true;

    # minimum amount of swapping without disabling it entirely
    boot.kernel.sysctl = { "vm.swappiness" = lib.mkDefault 1; };

    documentation.man.generateCaches = true;
    documentation.dev.enable = true;

    # Shell integration for VTE terminals
    # Required for some gtk apps
    programs.bash.vteIntegration = lib.mkDefault true;
    programs.zsh.vteIntegration = lib.mkDefault true;
  };
}
