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
      WLR_DRM_DEVICES = "$IGPU_CARD";

      # Tells every app to use my iGPU unless I specially instruct it not to
      # I would have to use the `nvidia-offload` command
      # This also speeds up the startup time of apps using GPU, because my nvidia card is always powered off
      # source: https://sw.kovidgoyal.net/kitty/faq/#why-does-kitty-sometimes-start-slowly-on-my-linux-system
      # source: https://github.com/Einjerjar/nix/blob/172d17410cd0849f7028f80c0e2084b4eab27cc7/home/vars.nix#L30
      # source: https://github.com/NixOS/nixpkgs/pull/139354#issuecomment-926942682
      # __EGL_VENDOR_LIBRARY_FILENAMES =
      #   "${config.hardware.graphics.package}/share/glvnd/egl_vendor.d/50_mesa.json:${config.hardware.nvidia.package}/share/glvnd/egl_vendor.d/10_nvidia.json";
    };

    # Mesa 25.1.7
    hardware.graphics.package = pkgs.nixpkgs-unstable.mesa;
    hardware.graphics.package32 = pkgs.nixpkgs-unstable.pkgsi686Linux.mesa;

    hardware.enableRedistributableFirmware = true;

    hardware.amdgpu.initrd.enable = true;
    hardware.amdgpu.opencl.enable = true;
    # NOTE: amdvlk can introduce black artifacts on GTK apps
    hardware.amdgpu.amdvlk.enable = true;

    hardware.nvidia = {
      open = false;
      modesetting.enable = true;
      nvidiaSettings = true;
      powerManagement.enable = true;
      powerManagement.finegrained = true;
      # NOTE: nvidia beta package gives problems with sleep/suspend
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      prime = {
        offload.enable = true;
        offload.enableOffloadCmd = true;
        # run `lspci | grep VGA`
        amdgpuBusId = "PCI:6:0:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };

    services.xserver.videoDrivers = lib.mkForce [ "modesetting" "nvidia" ];

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
    '';

    # fix audio power saving
    boot.extraModprobeConfig = ''
      options snd_hda_intel power_save=1
    '';

    boot.extraModulePackages = with config.boot.kernelPackages;
      [ lenovo-legion-module ];

    # NOTE: kernel 6.12.x gives me a lot of DRM issues
    boot.kernelPackages = lib.mkForce pkgs.linuxPackages_6_13;

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
