{
  inputs,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    inputs.nixos-hardware.nixosModules.common-gpu-amd
    inputs.nixos-hardware.nixosModules.common-pc-laptop-ssd
  ];

  config = {
    environment.systemPackages = with pkgs; [
      amdgpu_top
      rocmPackages.rocm-smi
      rocmPackages.rocminfo
    ];

    # NOTE: bleeding-edge amdgpu. On 2026-09-21 S3 resume left the RX 6800 XT
    # dead ("resume of IP block <gfx_v10_0> failed -110"); try LTS if it recurs.
    boot.kernelPackages = lib.mkForce pkgs.linuxPackages_latest;

    # s2idle keeps the dGPU's PCIe root port powered; S3 leaves it stuck in
    # D3hot. Next steps if it still fails: "pcie_aspm=off", then BIOS ErP off.
    boot.kernelParams = [
      "mem_sleep_default=s2idle"
      # lockup_timeout: long ComfyUI compute kernels (TunableOp tuning) starved the
      # gfx ring past the 10 s default, forcing a mode1 GPU reset that killed
      # Hyprland. 30 s turns that into a stall.
      "amdgpu.lockup_timeout=30000"
    ];
    # boot.kernelParams = [ "pcie_aspm=off" "amdgpu.aspm=0" ];

    # 244 = REISUB keys only, no debug dumps. Overrides the hardened 0 in
    # modules/nixos/security/network, so a wedged GPU still reboots cleanly.
    boot.kernel.sysctl."kernel.sysrq" = lib.mkForce 244;
    boot.kernelModules = [
      "msr" # cpu telemetry
      "k10temp" # ryzen 5900x
      "nct6775" # b550 motherboard
      "nvme"
      "drivetemp" # sata drive temp
      "hwmon_vid" # hw monitoring/power
    ];

    # enable ROCm
    boot.initrd.kernelModules = [ "amdgpu" ];

    networking = {
      # enable wol 2C:F0:5D:73:55:AB
      interfaces.enp6s0.wakeOnLan.enable = true;
    };

    # AMD has better battery life with PPD over TLP:
    # https://community.frame.work/t/responded-amd-7040-sleep-states/38101/13
    services.power-profiles-daemon.enable = true;

    # enable ROCm
    hardware.graphics.extraPackages = with pkgs; [
      rocmPackages.clr.icd
    ];

    hardware.amdgpu.initrd.enable = true;
    hardware.amdgpu.opencl.enable = true;

    # improve RAM usage
    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 50;
      priority = 100;
    };
    swapDevices = [
      {
        device = "/dev/disk/by-label/swap";
        priority = 10;
      }
    ];

    nix.settings.system-features = [ "gccarch-znver4" ];
  };
}
