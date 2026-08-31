pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property string value: ""

  function update() {
    if (!query.running)
      query.running = true;
  }

  function parseTotal(output) {
    const line = output.split("\n").find(candidate => candidate.trim().startsWith("Total"));
    const duration = line?.trim?.().split(/\s+/)?.[1] ?? "";
    const parts = duration.split(":");
    return parts.length >= 2 ? `${parts[0]}:${parts[1]}` : "";
  }

  Process {
    id: query

    command: ["timew"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: root.value = root.parseTotal(text ?? "")
    }
  }

  Timer {
    interval: 5000
    running: true
    repeat: true
    onTriggered: root.update()
  }
}
