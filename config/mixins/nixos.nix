{ config, pkgs, lib, inputs, ... }:

let
  isHidpi = config._isHidpi;
  isMbp = config.networking.hostName == "gmbp";
in
{
  imports = [
    # Install home manager
    inputs.home-manager.nixosModules.home-manager
  ];

  config = {
    # TODO: use overlay
    nixpkgs.config.packageOverrides = pkgs: rec {
      prevstable = import (inputs.prevstable) {
        # pass the nixpkgs config to the unstable alias
        # to ensure `allowUnfree = true;` is propagated:
        config = config.nixpkgs.config;
      };
    };

    # TODO: install cachix?

    environment.shellAliases = {
      open = "xdg-open";
    };

    # Remember private keys?
    programs.ssh.startAgent = true;

    programs.ssh.askPassword = "";

    boot = {
      loader = {
        grub.configurationLimit = 42;
        grub.efiSupport = true;
        grub.useOSProber = true;
        systemd-boot.configurationLimit = 42;
      };

      # Show nixos logo on boot/shutdown
      plymouth = {
        enable = true;
      };

      # Enable ntfs disks
      supportedFilesystems = [ "ntfs" ];
    };

    # Select internationalisation properties.
    i18n.defaultLocale = "en_US.UTF-8";

    console = {
      # font = if isHidpi then "ter-132n" else "Lat2-Terminus16";
      # earlySetup = true;
      keyMap = "us";
      # packages = [
      #   pkgs.terminus_font
      # ];
    };

    # Clear nixos store
    nix.autoOptimiseStore = true;

    security.sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };

    # Enable bluetooth
    hardware.bluetooth.enable = true;

    # Enable OpenGL
    hardware.opengl.enable = true;
    hardware.opengl.driSupport = true;

    # Hardware video acceleration?
    hardware.opengl.extraPackages = with pkgs; [
      vaapiVdpau
      libvdpau-va-gl
    ];
    hardware.opengl.extraPackages32 = with pkgs; [
      vaapiVdpau
      libvdpau-va-gl
    ];
    hardware.opengl.driSupport32Bit = !isMbp;

    # Enable audio
    # sound.enable = true;
    # Explicit PulseAudio support in applications
    # nixpkgs.config.pulseaudio = true;
    # hardware.pulseaudio.enable = true;
    # hardware.pulseaudio.support32Bit = true;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      # If you want to use JACK applications, uncomment this
      #jack.enable = true;
    };

    # Apply trim to SSDs
    services.fstrim.enable = true;

    documentation.man.generateCaches = true;
    documentation.dev.enable = true;
  };
}
