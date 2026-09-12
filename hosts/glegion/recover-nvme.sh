#!/usr/bin/env bash
# Recover the secondary NVMe (WD_BLACK SN850X) after its controller drops off
# the PCIe bus: CSTS=0xffffffff, "Disabling device after reset failure: -19",
# followed by ext4 journal abort and a read-only/shut-down /mnt/storage.
#
# `nvme reset` cannot fix this -- the controller no longer answers MMIO. What
# works is dropping the PCI function and re-enumerating it, which forces a cold
# controller init. The filesystem is then repaired offline before remounting.
#
# Nothing here may key off a device name:
#   - the controller is nvme0 or nvme1 depending on boot probe order;
#   - nvme_core.multipath=Y names namespaces after the subsystem instance, so
#     every rescan yields a new one (nvme1n1 -> nvme1n2 -> nvme1n3 ...).
# The drive is therefore located by PCI vendor:device, and the filesystem by
# its UUID.
set -euo pipefail

readonly PCI_VENDOR=0x15b7 # Sandisk / Western Digital
readonly PCI_DEVICE=0x5030 # WD_BLACK SN850X
readonly FS_UUID=8c519db6-0c66-45e9-bb00-cef1a211934d
readonly MOUNTPOINT=/mnt/storage
readonly MOUNT_UNIT=mnt-storage.mount
readonly DEV_BY_UUID="/dev/disk/by-uuid/${FS_UUID}"
readonly RESCAN_TRIES=3
readonly NAMESPACE_WAIT=20

# Re-exec as root before parsing: the parse loop below consumes "$@", so doing
# this afterwards would silently drop every flag. PATH is carried across
# because nvme-cli lives in the user profile, not the system one, and sudo
# sanitizes the environment.
if ((EUID != 0)); then
  exec sudo env PATH="$PATH" "$0" "$@"
fi

do_fsck=1
check_only=0

usage() {
  cat <<'EOF'
usage: script.sh [OPTIONS]

Recovers the secondary NVMe after it drops off the PCIe bus.

  --check       report state only, change nothing
  --no-fsck     skip the offline e2fsck after the drive returns
  -h, --help    show this help
EOF
}

while (($#)); do
  case "$1" in
  --check) check_only=1; shift ;;
  --no-fsck) do_fsck=0; shift ;;
  -h | --help) usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
  esac
done

log() { printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*" >&2; }
die() {
  printf '[%s] ERROR: %s\n' "$(date +%H:%M:%S)" "$*" >&2
  exit 1
}

find_bdf() {
  local dev
  for dev in /sys/bus/pci/devices/*; do
    [[ -e $dev/vendor ]] || continue
    if [[ $(<"$dev/vendor") == "$PCI_VENDOR" && $(<"$dev/device") == "$PCI_DEVICE" ]]; then
      basename "$dev"
      return 0
    fi
  done
  return 1
}

# Echoes the namespace block device holding our filesystem, or fails. A dangling
# by-uuid symlink (controller dead, udev not yet caught up) is rejected by -b.
find_namespace() {
  local dev
  dev=$(readlink -f "$DEV_BY_UUID" 2>/dev/null) || return 1
  [[ -b $dev ]] || return 1
  printf '%s\n' "$dev"
}

# A wedged controller keeps its PCI node and answers config-space reads, so the
# only reliable liveness test is a real block-layer ioctl against the namespace.
namespace_alive() {
  local dev size
  dev=$(find_namespace) || return 1
  size=$(blockdev --getsize64 "$dev" 2>/dev/null) || return 1
  ((size > 0))
}

mounted_options() { findmnt -no OPTIONS "$MOUNTPOINT" 2>/dev/null || true; }

# `nvme smart-log` wants a controller or whole-namespace node; the by-uuid path
# resolves to a partition, which it rejects.
whole_disk() {
  local name
  name=$(basename "$1")
  if [[ -e /sys/class/block/${name}/partition ]]; then
    basename "$(readlink -f "/sys/class/block/${name}/..")"
  else
    printf '%s\n' "$name"
  fi
}

fs_is_degraded() { grep -qE '\b(emergency_ro|shutdown)\b' <<<"$1"; }

do_rescan() {
  echo 1 >/sys/bus/pci/rescan
  udevadm settle --timeout=10 2>/dev/null || true
}

wait_for_namespace() {
  local tries=$((NAMESPACE_WAIT * 2))
  while ((tries-- > 0)); do
    namespace_alive && return 0
    sleep 0.5
  done
  return 1
}

report() {
  local bdf=$1 opts
  opts=$(mounted_options)
  printf '%-14s enable=%-3s power=%-5s mount=%s\n' \
    "$bdf" \
    "$(cat "/sys/bus/pci/devices/${bdf}/enable" 2>/dev/null || echo '?')" \
    "$(cat "/sys/bus/pci/devices/${bdf}/power/control" 2>/dev/null || echo '?')" \
    "${opts:-unmounted}" >&2
  if namespace_alive; then
    log "namespace: $(find_namespace) -- responding"
  else
    log "namespace: absent or not responding"
  fi
}

# Only meaningful while the controller answers; skipped silently otherwise.
print_smart() {
  local ns disk smart cw me
  ns=$(find_namespace) || return 0
  disk="/dev/$(whole_disk "$ns")"
  if ! command -v nvme >/dev/null; then
    log "nvme-cli not on PATH; skipping SMART for ${disk}"
    return 0
  fi
  log "SMART summary for ${disk}"
  smart=$(nvme smart-log "$disk" 2>/dev/null || true)
  if [[ -z $smart ]]; then
    log "could not read SMART"
    return 0
  fi
  grep -E 'critical_warning|media_errors|num_err_log_entries|percentage_used|available_spare|^temperature|unsafe_shutdowns|Critical Composite|Thermal Management T[12] Trans' <<<"$smart" >&2 || true

  cw=$(awk -F: '/^critical_warning/{gsub(/[ \t]/,"",$2); print $2; exit}' <<<"$smart")
  me=$(awk -F: '/^media_errors/{gsub(/[ \t]/,"",$2); print $2; exit}' <<<"$smart")
  if [[ ${cw:-0} != 0 || ${me:-0} != 0 ]]; then
    log "WARNING: critical_warning=${cw:-?} media_errors=${me:-?} -- the drive itself may be failing; back it up"
  fi
}

log "looking for ${PCI_VENDOR}:${PCI_DEVICE}"
bdf=$(find_bdf) || bdf=""
if [[ -z $bdf ]]; then
  log "absent from the PCI bus entirely; rescanning"
  do_rescan
  bdf=$(find_bdf) || die "no ${PCI_VENDOR}:${PCI_DEVICE} device found even after a rescan"
fi
log "found at ${bdf}"
report "$bdf"

alive=0
if namespace_alive; then
  alive=1
fi
opts=$(mounted_options)

if ((alive)) && [[ -n $opts ]] && ! fs_is_degraded "$opts"; then
  log "nothing to recover: ${opts}"
  print_smart
  exit 0
fi

if ((alive)); then
  if [[ -n $opts ]]; then
    log "filesystem is shut down (${opts}); repairing before remount"
  else
    log "drive is healthy but ${MOUNTPOINT} is not mounted; checking before mount"
  fi
fi

if ((check_only)); then
  print_smart
  log "--check: stopping here"
  exit 0
fi

# --- detach the dead filesystem -------------------------------------------
# Lazy unmount: the FS is already shut down so no dirty data can be lost, and a
# plain umount hangs or fails on the dead superblock.
if [[ -n $(mounted_options) ]]; then
  log "stopping ${MOUNT_UNIT} and detaching ${MOUNTPOINT}"
  systemctl stop "$MOUNT_UNIT" 2>/dev/null || true
  umount -l "$MOUNTPOINT" 2>/dev/null || true
  sleep 1
  [[ -z $(mounted_options) ]] || die "${MOUNTPOINT} is still mounted; refusing to pull the PCI device out from under it"
fi

# --- drop the wedged function and re-enumerate -----------------------------
recovered=0
if ((alive)); then
  # controller is fine; only the filesystem needed repair
  recovered=1
else
  for ((attempt = 1; attempt <= RESCAN_TRIES; attempt++)); do
    log "attempt ${attempt}/${RESCAN_TRIES}: removing ${bdf}"
    if [[ -e /sys/bus/pci/devices/${bdf}/remove ]]; then
      echo 1 >"/sys/bus/pci/devices/${bdf}/remove" || true
      sleep 2
    fi

    log "rescanning the PCI bus"
    do_rescan

    bdf=$(find_bdf) || bdf=""
    if [[ -n $bdf ]] && wait_for_namespace; then
      log "controller re-initialised at ${bdf}"
      recovered=1
      break
    fi
    log "still down"
    sleep 3
  done
fi

if ((recovered == 0)); then
  cat >&2 <<'EOF'

ERROR: the controller did not come back after a PCI remove + rescan.
A warm reboot will probably not fix it either -- the drive needs a real power
cycle:

  1. shut down (not reboot)
  2. unplug the AC adapter
  3. hold the power button for 30 s to drain the rail
  4. wait ~1 min, then boot

If it survives a cold boot but keeps dropping, the drive or its M.2 slot is the
problem, not the kernel.
EOF
  exit 1
fi

# --- repair the filesystem offline ----------------------------------------
# The journal aborted when the controller died, so the on-disk superblock state
# is stale and transactions are un-replayed. This must happen while unmounted:
# e2fsck refuses to touch a mounted filesystem.
[[ -z $(mounted_options) ]] || die "${MOUNTPOINT} got mounted during recovery; not running e2fsck"

if ((do_fsck)); then
  ns=$(find_namespace) || die "${DEV_BY_UUID} did not appear"
  log "running e2fsck -fy on ${ns}"
  rc=0
  e2fsck -fy "$ns" || rc=$?
  # 0 = clean, 1 = errors corrected, 2 = corrected + reboot advised.
  ((rc <= 2)) || die "e2fsck failed with status ${rc}; not mounting"
  ((rc == 0)) && log "e2fsck: clean" || log "e2fsck: repaired (status ${rc})"
else
  log "skipping e2fsck (--no-fsck)"
fi

# --- remount and verify ----------------------------------------------------
log "mounting ${MOUNTPOINT}"
systemctl start "$MOUNT_UNIT"

opts=$(mounted_options)
[[ -n $opts ]] || die "${MOUNTPOINT} did not mount"
fs_is_degraded "$opts" && die "mounted but still degraded: ${opts}"
log "mounted: ${opts}"

probe="${MOUNTPOINT}/.recover-probe.$$"
if echo ok >"$probe" && sync && rm -f "$probe"; then
  log "write test: OK"
else
  rm -f "$probe" 2>/dev/null || true
  die "write test failed -- filesystem is not usable"
fi

print_smart
log "recovered"
