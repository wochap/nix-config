pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// up/down run as the user thanks to `tailscale set --operator` (enableOperator),
// starting/stopping tailscaled goes through polkit like SFirewall
Singleton {
  id: root

  property bool available: false
  property bool isActive: false
  property bool needsLogin: false
  property string ip: ""

  function toggle() {
    // `tailscale up` without flags reuses the stored prefs (login server)
    toggleProcess.command = ["bash", "-c", root.isActive
      ? "tailscale down; systemctl stop tailscaled.service"
      : "systemctl start tailscaled.service && tailscale up"];
    root.isActive = !root.isActive;
    toggleProcess.running = true;
  }

  function getState() {
    getStateProcess.running = true;
  }

  Process {
    id: toggleProcess

    onExited: root.getState()
  }

  Process {
    id: getStateProcess

    running: true
    command: ["bash", "-c", `
        command -v tailscale &>/dev/null || exit 0
        systemctl is-active --quiet tailscaled.service || { echo stopped; exit 0; }
        tailscale status --json --peers=false 2>/dev/null || echo stopped
      `]

    stdout: StdioCollector {
      id: getStateCollector

      onStreamFinished: {
        const output = getStateCollector.text.trim();
        root.available = output !== "";
        if (!root.available || output === "stopped") {
          root.isActive = false;
          root.needsLogin = false;
          root.ip = "";
          return;
        }
        try {
          const status = JSON.parse(output);
          root.isActive = status.BackendState === "Running";
          root.needsLogin = status.BackendState === "NeedsLogin";
          root.ip = status.Self?.TailscaleIPs?.[0] ?? "";
        } catch (e) {
          root.isActive = false;
        }
      }
    }
  }
}
