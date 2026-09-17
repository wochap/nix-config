pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  property bool available: false
  property int percentage: 0
  signal changed

  function set(value) {
    Quickshell.execDetached(["bash", "-c", `shell-backlight --set ${value}`]);
  }

  Process {
    command: ["bash", "-c", "compgen -G '/sys/class/backlight/*' >/dev/null && echo yes || echo no"]
    running: true

    stdout: StdioCollector {
      onStreamFinished: {
        root.available = text.trim() === "yes";
      }
    }
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
