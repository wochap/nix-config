pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property bool isActive: false

  function toggle() {
    toggleProcess.running = true;
  }

  function getState() {
    getStatusProcess.running = true;
  }

  Process {
    id: getStatusProcess

    running: true
    command: ["bash", "-c", "shell-battery-saver --status"]
    stdout: StdioCollector {
      id: statusCollector

      onStreamFinished: {
        const output = statusCollector.text.trim();
        root.isActive = output === "true";
      }
    }
  }

  Process {
    id: toggleProcess

    command: ["bash", "-c", "shell-battery-saver --toggle"]
    stdout: StdioCollector {
      onStreamFinished: {
        root.getState();
      }
    }
  }
}
