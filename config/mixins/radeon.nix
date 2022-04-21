{ config, pkgs, lib, ... }:

{
  config = {
    boot.initrd.kernelModules = [ "amdgpu" ];
    boot.blacklistedKernelModules = [ "radeon" ];

    environment.systemPackages = [ pkgs.radeontop ];

    services.xserver = {
      videoDrivers = [ "amdgpu" ];

      deviceSection = ''
        # fix screen tearing?
        Option "TearFree" "true"

        # enable FreeSync
        Option "VariableRefresh" "true"
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
