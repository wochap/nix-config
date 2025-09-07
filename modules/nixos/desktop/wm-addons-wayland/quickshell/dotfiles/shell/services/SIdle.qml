pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  property bool isIdle: false

  Process {
    command: ["shell-idle", "--listen"]
    running: true
    stdout: SplitParser {
      onRead: data => {
        const isIdle = JSON.parse(data);
        root.isIdle = isIdle;
      }
    }
  }
}
