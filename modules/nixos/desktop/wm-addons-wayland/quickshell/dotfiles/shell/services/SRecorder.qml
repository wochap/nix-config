pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property bool isRecording: false

  Process {
    command: ["shell-recorder", "--listen"]
    running: true
    stdout: SplitParser {
      onRead: data => {
        const isRecording = JSON.parse(data);
        root.isRecording = isRecording;
      }
    }
  }
}
