pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property bool isLock: false

  Process {
    command: ["shell-capslock"]
    running: true
    stdout: SplitParser {
      onRead: data => {
        const isLock = JSON.parse(data);
        root.isLock = isLock;
      }
    }
  }
}
