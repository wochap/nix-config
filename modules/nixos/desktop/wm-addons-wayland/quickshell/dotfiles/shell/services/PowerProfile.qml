pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  property string icon: ""

  Process {
    command: ["shell-powerprofile", "--listen"]
    running: true
    stdout: SplitParser {
      onRead: data => {
        const profile = data;
        if (profile === "performance") {
          root.icon = "rocket";
        } else {
          root.icon = "nest_eco_leaf";
        }
      }
    }
  }
}
