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
    root.isActive = false;
    Quickshell.execDetached(["nixos-container", "stop", "sandbox"]);
  }

  function enable() {
    root.isActive = true;
    Quickshell.execDetached(["nixos-container", "start", "sandbox"]);
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
        if ! command -v nixos-container &>/dev/null; then
          echo unavailable
        elif ! status="$(nixos-container status sandbox 2>/dev/null)"; then
          echo unavailable
        elif [[ "$status" == "up" ]]; then
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
}
