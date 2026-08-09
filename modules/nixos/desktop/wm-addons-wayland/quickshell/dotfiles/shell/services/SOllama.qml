pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property bool isActive: false

  function disable() {
    root.isActive = false;
    Quickshell.execDetached(["bash", "-c", "systemctl stop ollama.service"]);
  }

  function enable() {
    root.isActive = true;
    Quickshell.execDetached(["bash", "-c", "systemctl start ollama.service"]);
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
    command: ["bash", "-c", `[[ "$(systemctl is-active ollama.service)" == "active" ]] && echo true || echo false`]
    stdout: StdioCollector {
      id: getStateCollector

      onStreamFinished: {
        const output = getStateCollector.text.trim();
        root.isActive = output === "true";
      }
    }
  }
}
