pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property bool connected: false
  property string type: "Disconnected"
  property string ssid: ""
  property int signalStrength: 0

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
    command: ["shell-network", "--listen"]
    running: true
    stdout: SplitParser {
      onRead: data => {
        debounceTimer.restart();
      }
    }
  }

  Process {
    id: getStatus

    command: ["shell-network", "--get-status"]
    stdout: StdioCollector {
      id: statusCollector

      onStreamFinished: {
        if (statusCollector.text) {
          var status = JSON.parse(statusCollector.text);
          root.type = status.type;
          root.ssid = status.ssid;
          root.signalStrength = status.signal;
          root.connected = status.connected;
        } else {
          root.type = "Disconnected";
          root.ssid = "";
          root.signalStrength = 0;
          root.connected = false;
        }
      }
    }
  }

  function getIcon() {
    const strength = root.signalStrength;
    if (root.type === "wifi") {
      if (!root.connected) {
        return "network-wireless-signal-none";
      }
      const icons = [[75, "network-wireless-signal-excellent"], [50, "network-wireless-signal-good"], [25, "network-wireless-signal-ok"], [0, "network-wireless-signal-weak"],];
      const icon = icons.find(([threshold, _]) => strength >= threshold);
      return icon?.[1] ?? "network-wireless-signal-none";
    } else if (root.type === "wired") {
      return "network-wired";
    }
    return "network-offline";
  }
}
