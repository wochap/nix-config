pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  readonly property string user: Quickshell.env("USER") ?? ""
  readonly property string host: hostnameFile.text().trim()
  property real uptimeSeconds: 0
  readonly property string uptime: root.formatUptime(root.uptimeSeconds)
  property string hyprlandVersion: ""
  property int batteryCycles: -1

  function formatUptime(seconds) {
    const total = Math.floor(seconds / 60);
    const days = Math.floor(total / 1440);
    const hours = Math.floor((total % 1440) / 60);
    const minutes = total % 60;
    const parts = [];
    if (days > 0) {
      parts.push(`${days}d`);
    }
    if (days > 0 || hours > 0) {
      parts.push(`${hours}h`);
    }
    // minutes only matter for the first day, keeps the header line short
    if (days === 0) {
      parts.push(`${minutes}m`);
    }
    return parts.join(" ");
  }

  // refresh the values that change over time
  function refresh() {
    uptimeFile.reload();
    cyclesProcess.running = true;
  }

  FileView {
    id: hostnameFile

    path: "/etc/hostname"
  }

  FileView {
    id: uptimeFile

    path: "/proc/uptime"
    onLoaded: {
      root.uptimeSeconds = parseFloat(uptimeFile.text().split(" ")[0]) || 0;
    }
  }

  Process {
    running: true
    command: ["hyprctl", "version", "-j"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const tag = JSON.parse(text).tag ?? "";
          // major.minor is enough for the header
          root.hyprlandVersion = tag.replace(/^v/, "").split("-")[0].split(".").slice(0, 2).join(".");
        } catch (e) {
          root.hyprlandVersion = "";
        }
      }
    }
  }

  Process {
    id: cyclesProcess

    running: true
    command: ["bash", "-c", "cat /sys/class/power_supply/BAT*/cycle_count 2>/dev/null | head -n1"]
    stdout: StdioCollector {
      onStreamFinished: {
        const cycles = parseInt(text.trim());
        root.batteryCycles = isNaN(cycles) ? -1 : cycles;
      }
    }
  }
}
