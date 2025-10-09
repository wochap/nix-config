pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  property int percentage: 0
  signal changed

  function set(value) {
    Quickshell.execDetached(["bash", "-c", `shell-backlight --set ${value}`]);
  }

  Process {
    command: ["shell-backlight", "--listen"]
    running: true
    stdout: SplitParser {
      onRead: data => {
        const _percentage = data;
        root.percentage = _percentage;
        root.changed();
      }
    }
  }
}
