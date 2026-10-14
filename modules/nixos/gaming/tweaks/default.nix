{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config._custom.gaming.tweaks;
  hasNvidia = lib.elem "nvidia" config.services.xserver.videoDrivers;
in
{
  imports = [ inputs.nix-gaming.nixosModules.platformOptimizations ];

  options._custom.gaming.tweaks.enable = lib.mkEnableOption { };

  # Performance tweaks shared by gdesktop (RX 6800 XT) and glegion (RTX 4060),
  # both on stock linuxPackages_6_18 (see _custom.gaming.chaotic for cachyos)
  config = lib.mkIf cfg.enable {
    # SteamOS sysctls: split_lock_mitigate=0, max_map_count, tcp_fin_timeout, cfs slice
    programs.steam.platformOptimizations.enable = true;

    # Proton-GE with ntsync, fsr4 and extra game fixes
    programs.steam.extraCompatPackages = with pkgs; [ proton-ge-bin ];

    boot.kernel.sysctl = {
      # no background compaction stalls while a game streams assets
      "vm.compaction_proactiveness" = 0;
      "vm.watermark_boost_factor" = 0;
      # both hosts swap to zram, readahead on swap-in only adds latency
      "vm.page-cluster" = 0;
    };

    # full preemption (PREEMPT_DYNAMIC), lower input/frame latency under load
    boot.kernelParams = [ "preempt=full" ];

    # ntsync (kernel >= 6.14), used by Proton 10/GE with PROTON_USE_NTSYNC=1
    boot.kernelModules = [ "ntsync" ];
    services.udev.extraRules = ''
      KERNEL=="ntsync", MODE="0644", TAG+="uaccess"
    '';

    # sched_ext scheduler: lower latency under load (gaming/compiles) than EEVDF.
    # Stock 6.18 kernel has CONFIG_SCHED_CLASS_EXT=y. glegion already sets it.
    services.scx = {
      enable = lib.mkDefault true;
      scheduler = lib.mkDefault "scx_lavd";
    };

    # gamemode renice needs the gamemode group
    _custom.user.extraGroups = [ "gamemode" ];
    programs.gamemode.settings.general = {
      renice = 10;
      softrealtime = "auto";
    };

    environment.sessionVariables = {
      PROTON_USE_NTSYNC = "1";
      # bigger shader caches, fewer recompiles/stutters (default is 1G)
      MESA_SHADER_CACHE_MAX_SIZE = "12G";
    }
    // lib.optionalAttrs hasNvidia {
      __GL_SHADER_DISK_CACHE_SIZE = "12000000000";
      __GL_SHADER_DISK_CACHE_SKIP_CLEANUP = "1";
      # DLSS/Reflex through dxvk-nvapi
      PROTON_ENABLE_NVAPI = "1";
    };
  };
}
