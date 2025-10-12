pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property string grayScaleFilterName: "grayscale"
  property string oledSaverFilterName: "oled-saver"
  property bool isGrayScaleActive: false
  property bool isOledSaverActive: false

  function disableAll() {
    root.isGrayScaleActive = false;
    root.isOledSaverActive = false;
    Quickshell.execDetached(["bash", "-c", "hyprshade off"]);
  }

  function enableGrayScale() {
    root.isOledSaverActive = false;
    root.isGrayScaleActive = true;
    Quickshell.execDetached(["bash", "-c", `hyprshade on ${root.grayScaleFilterName}`]);
  }

  function enableOledSaver() {
    root.isGrayScaleActive = false;
    root.isOledSaverActive = true;
    Quickshell.execDetached(["bash", "-c", `hyprshade on ${root.oledSaverFilterName}`]);
  }

  function toggleGrayScale() {
    if (root.isGrayScaleActive) {
      disableAll();
    } else {
      enableGrayScale();
    }
  }

  function toggleOledSaver() {
    if (root.isOledSaverActive) {
      disableAll();
    } else {
      enableOledSaver();
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
        root.isGrayScaleActive = output === root.grayScaleFilterName;
        root.isOledSaverActive = output === root.oledSaverFilterName;
      }
    }
  }
}
