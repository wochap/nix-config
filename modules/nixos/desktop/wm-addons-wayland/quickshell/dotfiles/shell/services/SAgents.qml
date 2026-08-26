pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property int runningCount: 0
  property int blockedCount: 0
  property var invocations: ({})

  function updateCounts() {
    let running = 0;
    let blocked = 0;

    for (const invocationId in root.invocations) {
      const status = root.invocations[invocationId]?.status;
      if (status === "running")
        running++;
      else if (status === "blocked")
        blocked++;
    }

    root.runningCount = running;
    root.blockedCount = blocked;
  }

  function readEnvelope(data) {
    let envelope;
    try {
      envelope = JSON.parse(data);
    } catch (error) {
      console.warn(`SAgents: invalid sessiontap output: ${error}`);
      return;
    }

    if (envelope.type === "snapshot") {
      const nextInvocations = {};
      for (const invocation of envelope.invocations ?? []) {
        if (invocation.status !== "stopped")
          nextInvocations[invocation.invocation_id] = invocation;
      }
      root.invocations = nextInvocations;
    } else if (envelope.type === "update" && envelope.snapshot?.invocation_id) {
      if (envelope.snapshot.status === "stopped")
        delete root.invocations[envelope.snapshot.invocation_id];
      else
        root.invocations[envelope.snapshot.invocation_id] = envelope.snapshot;
    } else {
      return;
    }

    root.updateCounts();
  }

  function reset() {
    root.invocations = {};
    root.updateCounts();
  }

  Process {
    id: listener

    command: ["sessiontap", "listen"]
    running: true
    stdout: SplitParser {
      onRead: data => root.readEnvelope(data)
    }
    onExited: exitCode => {
      root.reset();
      restartTimer.restart();
    }
  }

  Timer {
    id: restartTimer

    interval: 2000
    onTriggered: listener.running = true
  }
}
