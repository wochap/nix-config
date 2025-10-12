pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property bool isActive: false

  function disable() {
    root.isActive = false;
    Quickshell.execDetached(["bash", "-c", "systemctl --user stop docker.service"]);
    // TODO: is this network bridge linked to docker?
    // NOTE: it uses a lot of power
    Quickshell.execDetached(["bash", "-c", "pkexec ip link set br-c700d6064c27 down"]);
  }

  function enable() {
    root.isActive = true;
    Quickshell.execDetached(["bash", "-c", "systemctl --user start docker.service"]);
  }

  function toggle() {
    if (root.isActive) {
      disable();
    } else {
      enable();
    }
  }

  function getState() {
    getStateProcess.running = true;
  }

  Process {
    id: getStateProcess

    running: true
    command: ["bash", "-c", `[[ "$(systemctl --user is-active docker)" == "active" ]] && echo true || echo false`]
    stdout: StdioCollector {
      id: getStateCollector

      onStreamFinished: {
        const output = getStateCollector.text.trim();
        root.isActive = output === "true";
      }
    }
  }
}
