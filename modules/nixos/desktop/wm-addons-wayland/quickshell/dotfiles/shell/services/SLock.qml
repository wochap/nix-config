pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  property bool isLock: false

  Process {
    command: ["shell-lock", "--listen"]
    running: true
    stdout: SplitParser {
      onRead: data => {
        const isLock = JSON.parse(data);
        root.isLock = isLock;
      }
    }
  }
}

