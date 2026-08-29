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

  function replaceAgents(nextAgents) {
    let running = 0;
    let blocked = 0;

    for (const agentId in nextAgents) {
      const status = nextAgents[agentId]?.status;
      if (status === "running")
        running++;
      else if (status === "blocked")
        blocked++;
    }

    root.agents = nextAgents;
    root.runningCount = running;
    root.blockedCount = blocked;
  }

  function agentKey(sourceId, view) {
    if (typeof sourceId !== "string" || sourceId.length === 0
        || typeof view?.invocation_id !== "string" || view.invocation_id.length === 0)
      return "";

    return `${sourceId}:${view.invocation_id}`;
  }

  function readEnvelope(data) {
    let envelope;
    try {
      envelope = JSON.parse(data);
    } catch (error) {
      console.warn(`SAgents: invalid sessiontap output: ${error}`);
      return;
    }
    if (envelope === null || typeof envelope !== "object") {
      console.warn("SAgents: malformed sessiontap envelope");
      return;
    }

    if (envelope.type === "snapshot") {
      if (!Array.isArray(envelope.agents)) {
        console.warn("SAgents: malformed sessiontap snapshot");
        return;
      }

      const nextAgents = {};
      for (const sourceAgent of envelope.agents) {
        const agent = sourceAgent?.view;
        const key = root.agentKey(sourceAgent?.source_id, agent);
        if (key !== "" && agent.status !== "stopped")
          nextAgents[key] = agent;
      }
      root.replaceAgents(nextAgents);
    } else if (envelope.type === "update") {
      const key = root.agentKey(envelope.source_id, envelope.view);
      if (key === "") {
        console.warn("SAgents: malformed sessiontap update");
        return;
      }

      // Updates are complete resulting views. Copy the map before replacing
      // one entry so QML bindings also observe metadata-only changes.
      const nextAgents = Object.assign({}, root.agents);
      if (envelope.view.status === "stopped")
        delete nextAgents[key];
      else
        nextAgents[key] = envelope.view;
      root.replaceAgents(nextAgents);
    } else {
      return;
    }
  }

  function reset() {
    root.replaceAgents({});
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
