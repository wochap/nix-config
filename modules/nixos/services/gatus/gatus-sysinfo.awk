@load "time"

function json_escape(s) {
  gsub(/\\/, "\\\\", s)
  gsub(/"/, "\\\"", s)
  return s
}

function read_sample(s,    line, n, f, parts, iface, nf, i, tot, idl, has_avail) {
  delete s
  s["ts"] = gettimeofday()

  # /proc/stat
  s["cpu_total"] = 0
  s["cpu_idle"] = 0
  s["cpu_cores"] = 0
  while ((getline line < "/proc/stat") > 0) {
    n = split(line, f, " ")
    if (f[1] == "cpu") {
      tot = 0
      for (i = 2; i <= 11 && i <= n; i++) {
        tot += f[i] + 0
      }
      idl = (f[5] + 0) + (f[6] + 0)
      s["cpu_total"] = tot
      s["cpu_idle"] = idl
    } else if (f[1] ~ /^cpu[0-9]+$/) {
      s["cpu_cores"]++
    }
  }
  close("/proc/stat")

  # /proc/loadavg
  s["load1"] = 0
  s["load5"] = 0
  s["load15"] = 0
  if ((getline line < "/proc/loadavg") > 0) {
    split(line, f, " ")
    s["load1"] = f[1] + 0
    s["load5"] = f[2] + 0
    s["load15"] = f[3] + 0
  }
  close("/proc/loadavg")

  # /proc/uptime
  s["uptime_sec"] = 0
  if ((getline line < "/proc/uptime") > 0) {
    split(line, f, " ")
    s["uptime_sec"] = int(f[1] + 0)
  }
  close("/proc/uptime")

  # /proc/meminfo
  s["mem_total"] = 0
  s["mem_avail"] = 0
  s["mem_free"] = 0
  has_avail = 0
  s["swap_total"] = 0
  s["swap_free"] = 0
  while ((getline line < "/proc/meminfo") > 0) {
    split(line, f, " ")
    if (f[1] == "MemTotal:") {
      s["mem_total"] = (f[2] + 0) * 1024
    } else if (f[1] == "MemAvailable:") {
      s["mem_avail"] = (f[2] + 0) * 1024
      has_avail = 1
    } else if (f[1] == "MemFree:") {
      s["mem_free"] = (f[2] + 0) * 1024
    } else if (f[1] == "SwapTotal:") {
      s["swap_total"] = (f[2] + 0) * 1024
    } else if (f[1] == "SwapFree:") {
      s["swap_free"] = (f[2] + 0) * 1024
    }
  }
  close("/proc/meminfo")
  if (!has_avail) {
    s["mem_avail"] = s["mem_free"]
  }

  # /proc/net/dev (keep physical NIC totals separate from tailscale0 to avoid double-counting)
  s["rx_bytes"] = 0
  s["tx_bytes"] = 0
  s["ts_rx_bytes"] = 0
  s["ts_tx_bytes"] = 0
  while ((getline line < "/proc/net/dev") > 0) {
    if (index(line, ":") > 0) {
      split(line, parts, ":")
      iface = parts[1]
      gsub(/^[ \t]+|[ \t]+$/, "", iface)
      split(parts[2], nf, " ")
      if (iface == "tailscale0") {
        s["ts_rx_bytes"] += nf[1] + 0
        s["ts_tx_bytes"] += nf[9] + 0
      } else if (iface !~ /^(lo|tailscale.*|veth.*|podman.*|docker.*|br-.*|virbr.*|cni.*|flannel.*|tun.*|wg.*)$/) {
        s["rx_bytes"] += nf[1] + 0
        s["tx_bytes"] += nf[9] + 0
      }
    }
  }
  close("/proc/net/dev")
}

BEGIN {
  if (interval == "") interval = "@interval@" + 0
  if (host == "") host = "@host@"
  if (out == "") out = "@out@"
  if (mv_bin == "") mv_bin = "@mvBin@"
  if (interval <= 0) interval = 2
  tmp = out ".tmp"
  host_esc = json_escape(host)

  read_sample(prev)
  sleep(0.25)

  while (1) {
    read_sample(cur)

    dt = cur["ts"] - prev["ts"]
    if (dt <= 0) dt = interval

    d_total = cur["cpu_total"] - prev["cpu_total"]
    d_idle = cur["cpu_idle"] - prev["cpu_idle"]
    cpu_pct = (d_total > 0) ? (100.0 * (1.0 - (d_idle / d_total))) : 0.0
    if (cpu_pct < 0) cpu_pct = 0.0
    if (cpu_pct > 100) cpu_pct = 100.0

    mem_total = cur["mem_total"]
    mem_avail = cur["mem_avail"]
    mem_used = mem_total - mem_avail
    if (mem_used < 0) mem_used = 0
    mem_pct = (mem_total > 0) ? (100.0 * mem_used / mem_total) : 0.0
    swap_total = cur["swap_total"]
    swap_used = swap_total - cur["swap_free"]
    if (swap_used < 0) swap_used = 0

    d_rx = cur["rx_bytes"] - prev["rx_bytes"]
    d_tx = cur["tx_bytes"] - prev["tx_bytes"]
    d_ts_rx = cur["ts_rx_bytes"] - prev["ts_rx_bytes"]
    d_ts_tx = cur["ts_tx_bytes"] - prev["ts_tx_bytes"]
    if (d_rx < 0) d_rx = 0
    if (d_tx < 0) d_tx = 0
    if (d_ts_rx < 0) d_ts_rx = 0
    if (d_ts_tx < 0) d_ts_tx = 0

    rx_bps = d_rx / dt
    tx_bps = d_tx / dt
    ts_rx_bps = d_ts_rx / dt
    ts_tx_bps = d_ts_tx / dt

    printf "{\"host\":\"%s\",\"timestamp\":%.0f,\"uptime_sec\":%.0f,\"cpu_pct\":%.1f,\"cpu_cores\":%d,\"load1\":%.2f,\"load5\":%.2f,\"load15\":%.2f,\"mem_total_bytes\":%.0f,\"mem_avail_bytes\":%.0f,\"mem_used_bytes\":%.0f,\"mem_pct\":%.1f,\"swap_total_bytes\":%.0f,\"swap_used_bytes\":%.0f,\"net\":{\"rx_bytes\":%.0f,\"tx_bytes\":%.0f,\"rx_bps\":%.0f,\"tx_bps\":%.0f,\"ts_rx_bytes\":%.0f,\"ts_tx_bytes\":%.0f,\"ts_rx_bps\":%.0f,\"ts_tx_bps\":%.0f}}\n", \
      host_esc, cur["ts"], cur["uptime_sec"], cpu_pct, cur["cpu_cores"], cur["load1"], cur["load5"], cur["load15"], \
      mem_total, mem_avail, mem_used, mem_pct, swap_total, swap_used, \
      cur["rx_bytes"], cur["tx_bytes"], rx_bps, tx_bps, \
      cur["ts_rx_bytes"], cur["ts_tx_bytes"], ts_rx_bps, ts_tx_bps > tmp
    close(tmp)

    system(mv_bin " -f \"" tmp "\" \"" out "\"")

    delete prev
    for (k in cur) prev[k] = cur[k]

    if (max_ticks > 0 && ++ticks >= max_ticks) break
    sleep(interval)
  }
}
