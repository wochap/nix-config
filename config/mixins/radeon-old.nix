{ config, pkgs, lib, ... }:

{
  config = {
    boot.initrd.kernelModules = [ "amdgpu" ];

    # for Southern Islands (SI ie. GCN 1) cards
    boot.kernelParams = [ "radeon.si_support=0" "amdgpu.si_support=1" ];

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
