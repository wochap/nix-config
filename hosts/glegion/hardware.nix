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
    hardware.amdgpu.initrd.enable = true;
    hardware.amdgpu.opencl.enable = true;

    hardware.nvidia = {
      open = false;
      modesetting.enable = true;
      nvidiaSettings = true;
      powerManagement.enable = true;
      powerManagement.finegrained = true;
      package = config.boot.kernelPackages.nvidiaPackages.beta;
      prime = {
        offload.enable = true;
        offload.enableOffloadCmd = true;
        amdgpuBusId = "PCI:6:0:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };
    services.xserver.videoDrivers = [ "nvidia" ];

    boot.extraModulePackages = with config.boot.kernelPackages;
      [
        # Doesn't work yet...
        # lenovo-legion-module # fails at build
      ];

    # kernel 6.10.2
    # boot.kernelPackages = lib.mkForce pkgs.linuxPackages_latest;

    boot.kernelParams = [
      # this doesn't fix my ACPI Bios errors :c
      # source: https://discordapp.com/channels/761178912230473768/1159412133117833286
      "acpi_osi=Linux"

      # Disables scatter/gather which was introduced with kernel version 6.2
      # It produces completely white or flashing screens when enabled while using the iGPU of Ryzen 7000-series CPUs (Raphael)
      "amdgpu.sg_display=0"
    ];

    console.font = "${pkgs.terminus_font}/share/consolefonts/ter-v32n.psf.gz";

    # bleeding edge mesa
    chaotic.mesa-git.enable = true;
    chaotic.mesa-git.fallbackSpecialisation = false;

    # better fps in games
    # requires linuxPackages_cachyos
    # docs: https://github.com/sched-ext/scx
    chaotic.scx.enable = true;
    # kernel 6.11.2
    boot.kernelPackages = lib.mkForce pkgs.linuxPackages_cachyos;

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
      WLR_DRM_DEVICES = "$IGPU_CARD";

      # Tells every app to use my iGPU unless I specially instruct it not to
      # I would have to use the `nvidia-offload` command
      # This also speeds up the startup time of apps using GPU, because my nvidia card is always powered off
      # source: https://sw.kovidgoyal.net/kitty/faq/#why-does-kitty-sometimes-start-slowly-on-my-linux-system
      # source: https://github.com/Einjerjar/nix/blob/172d17410cd0849f7028f80c0e2084b4eab27cc7/home/vars.nix#L30
      __EGL_VENDOR_LIBRARY_FILENAMES =
        "${config.hardware.graphics.package}/share/glvnd/egl_vendor.d/50_mesa.json:${config.hardware.graphics.package}/share/glvnd/egl_vendor.d/10_nvidia.json";
    };

    zramSwap.enable = true;

    # AMD has better battery life with PPD over TLP:
    services.auto-epp = {
      enable = lib.mkDefault false;
      settings.Settings.epp_state_for_BAT = "power";
      settings.Settings.epp_state_for_AC = "balance_performance";
    };

    # AMD has better battery life with PPD over TLP:
    # https://community.frame.work/t/responded-amd-7040-sleep-states/38101/13
    # TODO: build from git main branch, for better support
    services.power-profiles-daemon.enable = lib.mkDefault false;

    services.fwupd.enable = true;

    # improve performance on SSDs
    boot.initrd.luks.devices."luks-4fa1d0c5-2c4a-478f-a9ce-099e36b3b390".bypassWorkqueues =
      true;
    boot.initrd.luks.devices."luks-f73c3c32-9bc9-4a22-ab24-bd456988a628".bypassWorkqueues =
      true;
  };
}
