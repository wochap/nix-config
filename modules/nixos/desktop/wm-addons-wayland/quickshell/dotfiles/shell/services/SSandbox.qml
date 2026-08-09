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
    command: ["nixos-container", "status", "sandbox"]
    stdout: StdioCollector {
      id: getStateCollector

      onStreamFinished: {
        root.isActive = getStateCollector.text.trim() === "up";
      }
    }
  }
}
