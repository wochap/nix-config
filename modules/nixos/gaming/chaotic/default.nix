{ config, pkgs, lib, inputs, ... }:

let cfg = config._custom.gaming.chaotic;
in {
  imports = [ inputs.chaotic.nixosModules.default ];

  options._custom.gaming.chaotic.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ lan-mouse_git ];

    # bleeding edge mesa
    # NOTE: it will break NVIDIA's libgbm
    # chaotic.mesa-git = {
    #   enable = true;
    #   fallbackSpecialisation = false;
    # };

    # better fps in games
    # requires linuxPackages_cachyos
    # docs: https://github.com/sched-ext/scx
    # docs: https://github.com/chaotic-cx/nyx
    services.scx = {
      enable = true;
      package = pkgs.scx_git.full;
      scheduler = "scx_rustland";
    };

    boot.kernelPackages = lib.mkForce pkgs.linuxPackages_cachyos;
  };
}
