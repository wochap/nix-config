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
    Quickshell.execDetached(["bash", "-c", "systemctl --user stop docker.service"]);
  }

  function enable() {
    root.isActive = true;
    Quickshell.execDetached(["bash", "-c", "systemctl --user start docker.service"]);
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
        if ! systemctl --user cat docker.service &>/dev/null; then
          echo unavailable
        elif [[ "$(systemctl --user is-active docker.service)" == "active" ]]; then
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
