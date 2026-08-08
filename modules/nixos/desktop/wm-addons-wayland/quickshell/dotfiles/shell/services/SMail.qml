pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property int unread: 0

  Process {
    command: ["shell-mail", "--listen"]
    running: true
    stdout: SplitParser {
      onRead: data => {
        const count = parseInt(data.trim(), 10);
        root.unread = Number.isNaN(count) ? 0 : count;
      }
    }
  }
}
