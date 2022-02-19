{ config, pkgs, lib, ... }:

{
  config = {
    boot.initrd.kernelModules = [ "amdgpu" ];

    environment.systemPackages = [ pkgs.radeontop ];

    services.xserver = {
      videoDrivers = [ "amdgpu" ];

      deviceSection = ''
        # does it fix screen tearing? maybe...
        Option         "NoLogo" "1"
        Option         "RenderAccel" "1"
        Option         "TripleBuffer" "true"
        Option         "MigrationHeuristic" "greedy"
        Option         "AccelMethod" "sna"
        Option         "TearFree"    "true"
      '';
    };

    hardware = {
      # Hardware video acceleration?
      opengl.extraPackages = with pkgs; [ vaapiVdpau libvdpau-va-gl ];
      opengl.extraPackages32 = with pkgs; [ vaapiVdpau libvdpau-va-gl ];
    };
  };
}
