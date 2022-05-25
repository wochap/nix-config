{ config, pkgs, lib, ... }:

let cfg = config._custom.amdGpu;
in {
  options._custom.amdGpu = {
    enable = lib.mkEnableOption "activate AMD GPU";
    enableSouthernIslands = lib.mkEnableOption
      "activate AMD GPU Southern Islands (SI ie. GCN 1) cards";
  };

  config = lib.mkIf cfg.enable {
    boot.initrd.kernelModules = [ "amdgpu" ];

    # for Southern Islands (SI ie. GCN 1) cards
    boot.kernelParams = lib.mkIf cfg.enableSouthernIslands [
      "radeon.si_support=0"
      "amdgpu.si_support=1"
    ];

    boot.blacklistedKernelModules =
      lib.mkIf (cfg.enableSouthernIslands == false) [ "radeon" ];

    environment.systemPackages = [ pkgs.radeontop ];

    services.xserver = {
      videoDrivers = [ "amdgpu" ];

      deviceSection = ''
      '';
    };

    hardware = {
      # Hardware video acceleration?
      opengl.extraPackages = with pkgs; [
        amdvlk
        rocm-opencl-icd
        rocm-opencl-runtime
      ];
      opengl.extraPackages32 = with pkgs; [ ];
    };
  };

}
