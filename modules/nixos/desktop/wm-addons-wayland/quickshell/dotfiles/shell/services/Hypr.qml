pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
  id: root

  property var activeWindow: null
  property var clients: []
  property var clientsByWorkspaceId: ({})
  property var addresses: []
  property var clientsByAddress: ({})
  property var workspaces: []
  property var workspacesIds: []
  property var workspacesById: ({})
  property var workspacesByMonitorId: []
  property var activeWorkspace: null
  property var monitors: []
  property var monitorsById: ({})
  property var layers: ({})
  property string submap: ""

  function updateClientList() {
    getClients.running = true;
    getActiveWindow.running = true;
  }
  function updateLayers() {
    getLayers.running = true;
  }
  function updateMonitors() {
    getMonitors.running = true;
  }
  function updateWorkspaces() {
    getWorkspaces.running = true;
    getActiveWorkspace.running = true;
  }
  function updateAll() {
    updateClientList();
    updateMonitors();
    updateLayers();
    updateWorkspaces();
  }

  Timer {
    id: debounceTimer

    interval: 50
    repeat: false
    onTriggered: root.updateAll()
  }

  Component.onCompleted: {
    root.updateAll();
  }

  Connections {
    target: Hyprland

    function onRawEvent(event) {
      debounceTimer.restart();
      if (event.name === "submap") {
        root.submap = event.data;
      }
    }
  }

  Process {
    id: getClients

    command: ["hyprctl", "clients", "-j"]
    stdout: StdioCollector {
      id: clientsCollector
      onStreamFinished: {
        root.clients = JSON.parse(clientsCollector.text);
        root.clientsByAddress = root.clients.reduce((result, client) => (Object.assign(result, {
              [client.address]: client
            })), {});
        root.clientsByWorkspaceId = root.workspaces.reduce((result, workspace) => (Object.assign(result, {
              [workspace.id]: root.clients.filter(client => client.workspace.id === workspace.id)
            })), {});
        root.addresses = root.clients.map(client => client.address);
      }
    }
  }

  Process {
    id: getMonitors

    command: ["hyprctl", "monitors", "-j"]
    stdout: StdioCollector {
      id: monitorsCollector
      onStreamFinished: {
        root.monitors = JSON.parse(monitorsCollector.text);
        root.monitorsById = root.monitors.reduce((result, monitor) => (Object.assign(result, {
              [monitor.id]: monitor
            })), {});
      }
    }
  }

  Process {
    id: getLayers

    command: ["hyprctl", "layers", "-j"]
    stdout: StdioCollector {
      id: layersCollector
      onStreamFinished: {
        root.layers = JSON.parse(layersCollector.text);
      }
    }
  }

  Process {
    id: getWorkspaces

    command: ["hyprctl", "workspaces", "-j"]
    stdout: StdioCollector {
      id: workspacesCollector
      onStreamFinished: {
        root.workspaces = JSON.parse(workspacesCollector.text);
        root.workspacesById = root.workspaces.reduce((result, workspace) => (Object.assign(result, {
              [workspace.id]: workspace
            })), {});
        root.workspacesIds = root.workspaces.map(workspace => workspace.id);
        root.workspacesByMonitorId = root.workspaces.reduce((result, workspace) => (Object.assign(result, {
              [workspace.monitorID]: (result?.[workspace.monitorID] ?? []).concat(workspace)
            })), {});
      }
    }
  }

  Process {
    id: getActiveWorkspace

    command: ["hyprctl", "activeworkspace", "-j"]
    stdout: StdioCollector {
      id: activeWorkspaceCollector
      onStreamFinished: {
        const _activeWorkspace = JSON.parse(activeWorkspaceCollector.text);
        root.activeWorkspace = _activeWorkspace?.monitor ? _activeWorkspace : null;
      }
    }
  }

  Process {
    id: getActiveWindow

    command: ["hyprctl", "activewindow", "-j"]
    stdout: StdioCollector {
      id: activeWindowCollector
      onStreamFinished: {
        const _activeWindow = JSON.parse(activeWindowCollector.text);
        root.activeWindow = _activeWindow?.address ? _activeWindow : null;
      }
    }
  }
}
