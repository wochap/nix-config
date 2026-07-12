pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property bool isActive: false

  Process {
    command: ["shell-offlinemsmtp", "--listen"]
    running: true
    stdout: SplitParser {
      onRead: data => {
        const isActive = JSON.parse(data);
        root.isActive = isActive;
      }
    }
  }
}
