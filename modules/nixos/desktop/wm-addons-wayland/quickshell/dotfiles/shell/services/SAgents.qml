pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property int runningCount: 0
  property int blockedCount: 0
  property var agents: ({})

  function updateCounts() {
    let running = 0;
    let blocked = 0;

    for (const agentId in root.agents) {
      const status = root.agents[agentId]?.status;
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
      const nextAgents = {};
      for (const sourceAgent of envelope.agents ?? []) {
        const agent = sourceAgent.view;
        if (agent?.status !== "stopped") {
          const key = `${sourceAgent.source_id}:${agent.invocation_id}`;
          nextAgents[key] = agent;
        }
      }
      root.agents = nextAgents;
    } else if (envelope.type === "update" && envelope.view?.invocation_id) {
      const key = `${envelope.source_id}:${envelope.view.invocation_id}`;
      if (envelope.view.status === "stopped")
        delete root.agents[key];
      else
        root.agents[key] = envelope.view;
    } else {
      return;
    }

    root.updateCounts();
  }

  function reset() {
    root.agents = {};
    root.updateCounts();
  }

  Process {
    id: listener

    command: ["sessiontap-hub", "listen"]
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
