pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property bool active: false
  property int temperature: 0

  function disable() {
    root.active = false;
    Quickshell.execDetached(["bash", "-c", "systemctl --user stop hyprsunset.service"]);
  }

  function enable() {
    root.active = true;
    Quickshell.execDetached(["bash", "-c", "systemctl --user start hyprsunset.service"]);
  }

  function toggle() {
    if (root.active) {
      disable();
    } else {
      enable();
    }
  }

  function getState() {
    getStatus.running = true;
  }

  function setTemperature(value) {
    root.temperature = value;
    Quickshell.execDetached(["bash", "-c", `hyprctl hyprsunset temperature ${value}`]);
  }

  Process {
    id: getStatus

    running: true
    command: ["hyprctl", "hyprsunset", "temperature"]
    stdout: StdioCollector {
      id: statusCollector

      onStreamFinished: {
        const output = statusCollector.text.trim();
        if (output.length === 0 || output.startsWith("Couldn't")) {
          root.active = false;
        } else {
          root.active = true;
          root.temperature = output;
        }
      }
    }
  }
}
