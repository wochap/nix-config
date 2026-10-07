{ config, lib, ... }:

let
  cfg = config._custom.security.kernel;
in
{
  options._custom.security.kernel = {
    enable = lib.mkEnableOption { };
    zeroOnFree = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Pass `init_on_free=1`. Zeroes every freed page/slab object, the most
        expensive of the hardening params (memory-bandwidth bound, hurts
        allocation-heavy workloads like games/compilers). Disable on hosts
        where performance matters more than defense-in-depth; `init_on_alloc`
        stays on and covers most of the info-leak surface.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    boot.kernelParams = [
      # Zero heap allocations on alloc/free (prevents info leaks from freed memory)
      "init_on_alloc=1"
      # Prevent slab merging (common exploit technique)
      "slab_nomerge"
      # Randomize kernel stack offset per syscall
      "randomize_kstack_offset=1"
      # Remove legacy vsyscall page (exploit target)
      "vsyscall=none"
      # Disable debugfs (reduces attack surface)
      "debugfs=off"
    ]
    ++ lib.optional cfg.zeroOnFree "init_on_free=1";

    boot.kernel.sysctl = {
      # Hide kernel pointers from all users (not just unprivileged)
      "kernel.kptr_restrict" = 2;
      # Restrict dmesg to CAP_SYSLOG
      "kernel.dmesg_restrict" = 1;
      # Only parent process can ptrace its children
      "kernel.yama.ptrace_scope" = 1;
      # Block unprivileged BPF (exploit vector)
      "kernel.unprivileged_bpf_disabled" = 1;
      # Harden BPF JIT against code reuse attacks
      "net.core.bpf_jit_harden" = 2;
      # Restrict perf events to root
      "kernel.perf_event_paranoid" = 3;
    };

    # Prevent overwriting kernel image from userspace
    security.protectKernelImage = true;
  };
}
