pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property bool isActive: false
  property string ip: ""

  Process {
    command: ["shell-wireguard", "--listen"]
    running: true
    stdout: SplitParser {
      onRead: data => {
        const payload = JSON.parse(data);
        root.isActive = payload.status;
        root.ip = payload.ip;
      }
    }
  }
}
