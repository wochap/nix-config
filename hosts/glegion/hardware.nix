{ config, inputs, lib, pkgs, ... }:

{
  imports = [
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    inputs.nixos-hardware.nixosModules.common-cpu-amd-raphael-igpu
    inputs.nixos-hardware.nixosModules.common-gpu-amd
    inputs.nixos-hardware.nixosModules.common-gpu-nvidia-nonprime
    inputs.nixos-hardware.nixosModules.common-pc-laptop
    inputs.nixos-hardware.nixosModules.common-pc-laptop-ssd
  ];

  config = {
    environment.systemPackages = with pkgs; [
      lenovo-legion
      (nvtopPackages.nvidia.override { amd = true; })
      amdgpu_top
    ];
    environment.sessionVariables = {
      # Vulkan reduces power usage
      # WLR_RENDERER = "vulkan";

      # Use iGPU for wlroots window managers
      IGPU_CARD = "$(readlink -f /dev/dri/by-path/pci-0000:06:00.0-card)";
      DGPU_CARD = "$(readlink -f /dev/dri/by-path/pci-0000:01:00.0-card)";
    };

    # Mesa 25.1.6
    # update to v25.2.x when the following is fixed
    # https://gitlab.freedesktop.org/mesa/mesa/-/issues/13719
    hardware.graphics = {
      package = pkgs.prevstable-mesa.mesa;
      package32 = pkgs.prevstable-mesa.pkgsi686Linux.mesa;
      extraPackages = with pkgs.prevstable-mesa; [
        # https://discourse.nixos.org/t/unable-to-find-gpu/19818/4
        vulkan-loader
        # video acceleration libs
        libva
        libvdpau
        # NVIDIA VA-API support
        # nvidia-vaapi-driver
      ];
      extraPackages32 = with pkgs.prevstable-mesa.pkgsi686Linux;
        [ vulkan-loader ];
    };

    hardware.enableRedistributableFirmware = true;

    hardware.amdgpu.initrd.enable = true;
    hardware.amdgpu.opencl.enable = true;
    # NOTE: amdvlk can introduce black artifacts on GTK apps
    hardware.amdgpu.amdvlk.enable = true;

    hardware.nvidia = {
      open = false;
      modesetting.enable = true;
      nvidiaSettings = true;
      powerManagement = {
        enable = true;
        finegrained = true;
      };
      dynamicBoost.enable = true;
      # NOTE: nvidia beta package gives problems with sleep/suspend
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      prime = {
        # force igpu to do all rendering
        # allowing to use hdmi ports without
        # dgpu consuming a lot of power
        reverseSync.enable = true;
        offload.enable = true;
        offload.enableOffloadCmd = true;
        # run `lspci | grep VGA`
        amdgpuBusId = "PCI:6:0:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };

    # disable power saving for the mt7921e driver
    # fixes wrong powertop energy report
    networking.wireless.iwd.settings.DriverQuirks.PowerSaveDisable = "mt7921e";

    services.xserver.videoDrivers = lib.mkForce [ "modesetting" "nvidia" ];

    # nvidia prime is better
    services.switcherooControl.enable = false;

    services.ucodenix = {
      enable = true;
      # docs: https://github.com/e-tho/ucodenix?tab=readme-ov-file#usage
      cpuModelId = "00A70F41";
    };

    # AMD has better battery life with PPD over TLP:
    # https://community.frame.work/t/responded-amd-7040-sleep-states/38101/13
    services.power-profiles-daemon.enable = true;

    services.udev.extraRules = ''
      # Enable USB autosuspend specifically for the Integrated Camera
      ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="04f2", ATTRS{idProduct}=="b7b6", TEST=="power/control", ATTR{power/control}="auto"

      # NOTE: these aren't needed for dGPU deep sleep
      # Automatically manage power state of NVIDIA PCI GPU
      ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{device}=="0x28a0", ATTR{power/control}="auto"
      # Automatically manage power state of NVIDIA Audio device
      ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{device}=="0x22be", ATTR{power/control}="auto"
    '';

    # fix audio power saving
    boot.extraModprobeConfig = ''
      # force lenovo-legion-module
      options legion_laptop force=1

      options snd_hda_intel power_save=1

      # prevents apps from crashing when GPU powers down and wakes back up
      options nvidia "NVreg_DynamicPowerManagementVideoMemoryThreshold=0"
      options nvidia "NVreg_PreserveVideoMemoryAllocations=1"
    '';

    boot.extraModulePackages = with config.boot.kernelPackages;
      [ lenovo-legion-module ];
    # blacklist ideapad_laptop to avoid conflicts with lenovo-legion-module.
    # NOTE: this also breaks the microphone mute key functionality.
    boot.blacklistedKernelModules = [ "ideapad_laptop" ];

    # NOTE: kernel 6.12.x gives me a lot of DRM issues
    # install kernel v6.16.8
    boot.kernelPackages = lib.mkForce pkgs.linuxPackages_6_16;

    boot.kernelParams = [
      # this doesn't fix my ACPI Bios errors :c
      # source: https://discordapp.com/channels/761178912230473768/1159412133117833286
      "acpi_osi=Linux"

      # TODO: change to deep when on battery
      # "mem_sleep_default=deep"
    ];

    # improve performance on SSDs
    boot.initrd.luks.devices."luks-4fa1d0c5-2c4a-478f-a9ce-099e36b3b390".bypassWorkqueues =
      true;
    boot.initrd.luks.devices."luks-f73c3c32-9bc9-4a22-ab24-bd456988a628".bypassWorkqueues =
      true;

    # improve RAM usage
    zramSwap.enable = true;

    nix.settings.system-features = [ "gccarch-znver4" ];

    console.font = "${pkgs.terminus_font}/share/consolefonts/ter-v32n.psf.gz";

    systemd.services."serial-getty@".enable = false;
  };
}
