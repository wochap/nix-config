pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
  id: root

  property var wifi: null
  property var wired: null
  property string icon: "network-offline"
  property string iconColor: Theme.options.text
  property string label: "Off"
  property string wifiIcon: "network-offline"
  property string wifiIconColor: Theme.options.text
  property string wifiLabel: "Off"

  function update() {
    getStatus.running = true;
  }

  function updateViewState() {
    if (root.wifi) {
      if (root.wifi.powered) {
        if (!root.wifi.connected) {
          root.icon = "network-wireless-signal-none";
          root.iconColor = Theme.options.red;
          root.label = "On";
        } else {
          const strength = root.wifi.signal;
          const icons = [[75, "network-wireless-signal-excellent"], [50, "network-wireless-signal-good"], [25, "network-wireless-signal-ok"], [0, "network-wireless-signal-weak"],];
          const icon = icons.find(([threshold, _]) => strength >= threshold);

          root.icon = icon?.[1] ?? "network-wireless-signal-none";
          root.iconColor = Theme.options.text;
          root.label = root.wifi.ssid;
        }
      } else {
        root.icon = "network-offline";
        root.iconColor = Theme.options.textDimmed;
        root.label = "Off";
      }
      root.wifiIcon = root.icon;
      root.wifiIconColor = root.iconColor;
      root.wifiLabel = root.label;
    }

    if (root.wired && root.wired.powered) {
      if (!root.wired.connected) {
        root.icon = "network-offline";
        root.iconColor = Theme.options.textDimmed;
        root.label = "Disconnected";
      } else {
        root.icon = "wired";
        root.iconColor = Theme.options.text;
        root.label = "Connected";
      }
    }

    if (!root.wifi && !root.wired) {
      root.icon = "network-offline";
      root.iconColor = Theme.options.textDimmed;
      root.label = "Off";
    }
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

  Connections {
    target: Theme

    function onChanged(event) {
      root.update();
    }
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

    command: ["shell-network", "--status"]
    stdout: StdioCollector {
      id: statusCollector

      onStreamFinished: {
        if (statusCollector.text) {
          var status = JSON.parse(statusCollector.text);
          root.wifi = status.wifi;
          root.wired = status.wired;
        } else {
          root.wifi = null;
          root.wired = null;
        }
        root.updateViewState();
      }
    }
  }

  function toggleWifiPower() {
    Quickshell.execDetached(["bash", "-c", "shell-network --toggle-wifi"]);
  }
}
