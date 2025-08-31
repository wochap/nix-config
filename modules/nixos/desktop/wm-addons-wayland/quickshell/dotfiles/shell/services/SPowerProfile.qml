pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

import qs.config

Singleton {
  id: root

  property string icon: ""
  property string iconColor: ""

  Process {
    command: ["shell-powerprofile", "--listen"]
    running: true
    stdout: SplitParser {
      onRead: data => {
        const profile = data;
        if (profile === "performance") {
          root.icon = "rocket";
          root.iconColor = Theme.options.red;
        } else if (profile === "balanced") {
          root.icon = "energy_savings_leaf";
          root.iconColor = Theme.options.yellow;
        } else {
          root.icon = "nest_eco_leaf";
          root.iconColor = Theme.options.green;
        }
      }
    }
  }
}
