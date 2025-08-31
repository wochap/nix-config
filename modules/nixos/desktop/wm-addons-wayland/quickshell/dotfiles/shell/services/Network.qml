pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
  id: root

  property bool connected: false
  property string type: "Disconnected"
  property string ssid: ""
  property int signalStrength: 0
  property string icon: "network-offline"
  property string iconColor: Theme.options.text

  function update() {
    getStatus.running = true;
  }

  // A debounce timer to prevent rapid updates when many signals are received
  Timer {
    id: debounceTimer
    interval: 50
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
        root.updateIcon();
      }
    }
  }

  function updateIcon() {
    const strength = root.signalStrength;
    if (root.type === "wifi") {
      if (!root.connected) {
        root.icon = "network-wireless-signal-none";
        root.iconColor = Theme.options.red;
        return;
      }
      const icons = [[75, "network-wireless-signal-excellent"], [50, "network-wireless-signal-good"], [25, "network-wireless-signal-ok"], [0, "network-wireless-signal-weak"],];
      const icon = icons.find(([threshold, _]) => strength >= threshold);
      root.icon = icon?.[1] ?? "network-wireless-signal-none";
      root.iconColor = Theme.options.text;
      return;
    } else if (root.type === "wired") {
      if (!root.connected) {
        root.icon = "network-offline";
        return;
      }
      root.icon = "wired";
      root.iconColor = Theme.options.text;
      return;
    }
    root.icon = "network-offline";
    root.iconColor = Theme.options.textDimmed;
  }
}
