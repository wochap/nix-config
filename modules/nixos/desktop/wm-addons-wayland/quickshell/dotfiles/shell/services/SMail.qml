pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property int unread: 0

  Process {
    id: process

    command: ["shell-mail"]
    running: true
    stdout: StdioCollector {
      id: stdioCollector

      onStreamFinished: data => {
        const count = parseInt(stdioCollector.text?.trim?.() ?? "0", 10);
        root.unread = Number.isNaN(count) ? 0 : count;
      }
    }
  }

  Timer {
    interval: 30_000
    running: true
    repeat: true
    onTriggered: {
      process.running = true;
    }
  }
}
