pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property bool available: false
  property bool isActive: false

  function disable() {
    toggleProcess.command = ["bash", "-c", "systemctl stop firewall.service"];
    toggleProcess.running = true;
  }

  function enable() {
    toggleProcess.command = ["bash", "-c", "systemctl start firewall.service"];
    toggleProcess.running = true;
  }

  function toggle() {
    if (root.isActive) {
      disable();
    } else {
      enable();
    }
  }

  function getState() {
    getStateProcess.running = true;
  }

  Process {
    id: getStateProcess

    running: true
    command: ["bash", "-c", `
        if ! systemctl cat firewall.service &>/dev/null; then
          echo unavailable
        elif [[ "$(systemctl is-active firewall.service)" == "active" ]]; then
          echo active
        else
          echo inactive
        fi
      `]

    stdout: StdioCollector {
      id: getStateCollector

      onStreamFinished: {
        const output = getStateCollector.text.trim();

        root.available = output !== "unavailable";
        root.isActive = output === "active";
      }
    }
  }

  // system unit, polkit agent prompts for auth; refresh state after it exits
  Process {
    id: toggleProcess

    stdout: StdioCollector {
      onStreamFinished: {
        root.getState();
      }
    }
  }
}
