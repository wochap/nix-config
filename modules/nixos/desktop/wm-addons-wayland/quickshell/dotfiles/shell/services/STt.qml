pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Running tt entries, pushed by `tt watch` (no polling). The snapshot and
// every entry.* event carry the full `running` list, so no other state.
Singleton {
  id: root

  property var running: []
  property int count: running.length
  property real now: Date.now()

  function title(entry) {
    return entry.task ? `#${entry.task.seq} ${entry.task.title}` : "";
  }

  function elapsed(entry) {
    const secs = Math.max(0, Math.floor((root.now - Date.parse(entry.start)) / 1000));
    const minutes = Math.floor(secs / 60) % 60;
    return `${Math.floor(secs / 3600)}:${String(minutes).padStart(2, "0")}`;
  }

  function stop(entryId) {
    Quickshell.execDetached(["tt", "stop", entryId]);
  }

  function stopAll() {
    Quickshell.execDetached(["tt", "stop", "--all"]);
  }

  Process {
    id: watcher

    command: ["tt", "watch", "--event", "entry.*"]
    running: true
    stdout: SplitParser {
      onRead: data => {
        try {
          const event = JSON.parse(data);
          if (event.running !== undefined)
            root.running = event.running;
        } catch (error) {}
      }
    }
    // Daemon restarted or tt missing: reconnect, the next snapshot resyncs
    onExited: {
      root.running = [];
      restart.start();
    }
  }

  Timer {
    id: restart

    interval: 3000
    onTriggered: watcher.running = true
  }

  Timer {
    interval: 1000
    running: root.count > 0
    repeat: true
    triggeredOnStart: true
    onTriggered: root.now = Date.now()
  }
}
