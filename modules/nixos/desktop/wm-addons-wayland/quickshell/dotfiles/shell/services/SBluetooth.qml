pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
  id: root

  property bool powered: false
  property bool scanning: false
  property int connectedDevices: 0
  property string icon: "bluetooth"
  property string iconColor: Theme.options.text

  function update() {
    getStatus.running = true;
  }

  function updateIcon() {
    if (!root.powered) {
      root.icon = "bluetooth_disabled";
      root.iconColor = Theme.options.textDimmed;
      return;
    }
    if (root.connectedDevices > 0) {
      root.icon = "bluetooth_connected";
      root.iconColor = Theme.options.text;
      return;
    }
    if (root.scanning) {
      root.icon = "bluetooth_searching";
      root.iconColor = Theme.options.green;
      return;
    }
    root.icon = "bluetooth";
    root.iconColor = Theme.options.text;
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
        root.updateIcon();
      }
    }
  }
}
