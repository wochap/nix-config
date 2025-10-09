pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property bool isGrayScaleActive: false

  function disableGrayScale() {
    root.isGrayScaleActive = false;
    Quickshell.execDetached(["bash", "-c", "hyprshade off"]);
  }

  function enableGrayScale() {
    root.isGrayScaleActive = true;
    Quickshell.execDetached(["bash", "-c", "hyprshade on grayscale"]);
  }

  function toggleGrayScale() {
    if (root.isGrayScaleActive) {
      disableGrayScale();
    } else {
      enableGrayScale();
    }
  }

  function getState() {
    getStatus.running = true;
  }

  Process {
    id: getStatus

    running: true
    command: ["bash", "-c", "hyprshade current"]
    stdout: StdioCollector {
      id: statusCollector

      onStreamFinished: {
        const output = statusCollector.text.trim();
        root.isGrayScaleActive = output === "grayscale";
      }
    }
  }
}
