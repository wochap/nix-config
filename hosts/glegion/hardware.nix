{ config, inputs, lib, pkgs, ... }:

{
  disabledModules = [ "services/hardware/auto-epp.nix" ];
  imports = [
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    inputs.nixos-hardware.nixosModules.common-cpu-amd-raphael-igpu
    inputs.nixos-hardware.nixosModules.common-gpu-amd
    inputs.nixos-hardware.nixosModules.common-gpu-nvidia
    inputs.nixos-hardware.nixosModules.common-pc-laptop
    inputs.nixos-hardware.nixosModules.common-pc-laptop-ssd
    inputs.nixos-hardware.nixosModules.common-hidpi

    "${inputs.unstable}/nixos/modules/services/hardware/auto-epp.nix"
  ];

  config = {
    hardware.amdgpu.amdvlk = true;
    hardware.amdgpu.loadInInitrd = true;
    hardware.amdgpu.opencl = true;

    hardware.nvidia = {
      modesetting.enable = true;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
    hardware.nvidia.prime = {
      amdgpuBusId = "PCI:5:0:0";
      nvidiaBusId = "PCI:1:0:0";
    };

    boot.extraModulePackages = with config.boot.kernelPackages; [
      # for steam i guess...
      nvidia_x11

      # Doesn't work yet...
      lenovo-legion-module
    ];

    # NOTE: kernel 6.7.0 gives artifacts
    boot.kernelPackages = lib.mkForce pkgs.unstable.linuxPackages_6_6;

    boot.kernelParams = [
      # this doesn't fix my ACPI Bios errors :c
      # source: https://discordapp.com/channels/761178912230473768/1159412133117833286
      "acpi_osi=Linux"

      # Disables scatter/gather which was introduced with kernel version 6.2
      # It produces completely white or flashing screens when enabled while using the iGPU of Ryzen 7000-series CPUs (Raphael)
      "amdgpu.sg_display=0"

      # Hide not harmful ACPI BIOS Errors (AE_ALREADY_EXISTS)
      # more info: https://forum.zorin.com/t/acpi-bios-error-help-to-make-sense-of-this/22035/2
      "loglevel=3"
    ];

    environment.systemPackages = with pkgs; [ lenovo-legion nvtop amdgpu_top ];
    environment.sessionVariables = {
      # Use iGPU for wlroots window managers
      IGPU_CARD = "$(readlink -f /dev/dri/by-path/pci-0000:05:00.0-card)";
      DGPU_CARD = "$(readlink -f /dev/dri/by-path/pci-0000:01:00.0-card)";
      WLR_DRM_DEVICES = "$IGPU_CARD";

      # Tells every app to use my iGPU unless I specially instruct it not to
      # I would have to use the `nvidia-offload` command
      # This also speeds up the startup time of apps using GPU, because my nvidia card is always powered off
      # source: https://sw.kovidgoyal.net/kitty/faq/#why-does-kitty-sometimes-start-slowly-on-my-linux-system
      # source: https://github.com/Einjerjar/nix/blob/172d17410cd0849f7028f80c0e2084b4eab27cc7/home/vars.nix#L30
      __EGL_VENDOR_LIBRARY_FILENAMES =
        "${pkgs.mesa.drivers}/share/glvnd/egl_vendor.d/50_mesa.json";
    };

    zramSwap.enable = true;

    hardware.bluetooth.powerOnBoot = false;

    # AMD has better battery life with PPD over TLP:
    services.auto-epp = {
      enable = lib.mkDefault true;
      package = pkgs.unstable.auto-epp;
      settings.Settings.epp_state_for_BAT = "power";
      settings.Settings.epp_state_for_AC = "balance_performance";
    };

    # AMD has better battery life with PPD over TLP:
    # https://community.frame.work/t/responded-amd-7040-sleep-states/38101/13
    # TODO: build from git main branch, for better support
    # services.power-profiles-daemon.enable = lib.mkDefault true;

    services.fwupd.enable = true;
  };
}
