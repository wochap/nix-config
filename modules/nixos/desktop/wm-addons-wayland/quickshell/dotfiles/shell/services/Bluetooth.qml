pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property bool powered: false
  property bool scanning: false
  property int connectedDevices: 0

  function update() {
    getStatus.running = true;
  }

  // A debounce timer to prevent rapid updates when many signals are received
  Timer {
    id: debounceTimer
    interval: 100
    repeat: false
    onTriggered: root.update()
  }

  Component.onCompleted: {
    root.update();
  }

  Process {
    command: ["shell-bluetooth", "--listen"]
    running: true
    stdout: SplitParser {
      onRead: data => {
        debounceTimer.restart();
      }
    }
  }

  Process {
    id: getStatus

    command: ["shell-bluetooth", "--get-status"]
    stdout: StdioCollector {
      id: statusCollector

      onStreamFinished: {
        if (statusCollector.text) {
          var status = JSON.parse(statusCollector.text);
          root.powered = status.powered;
          root.scanning = status.scanning;
          root.connectedDevices = status.connected_devices;
        } else {
          root.powered = false;
          root.scanning = false;
          root.connectedDevices = 0;
        }
      }
    }
  }

  function getIcon() {
    if (!root.powered) {
      return "bluetooth_disabled";
    }
    if (root.connectedDevices > 0) {
      return "bluetooth_connected";
    }
    if (root.scanning) {
      return "bluetooth_searching";
    }
    return "bluetooth";
  }
}
