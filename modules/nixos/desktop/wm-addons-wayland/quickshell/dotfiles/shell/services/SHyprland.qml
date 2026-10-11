pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
  id: root

  property var monocleState: ([])
  property var activeWindow: null
  property var clients: []
  property var clientsByWorkspaceId: ({})
  property var addresses: []
  property var clientsByAddress: ({})
  property var workspaces: []
  property var workspacesIds: []
  property var workspacesById: ({})
  property var activeWorkspace: null
  property var monitors: []
  property var monitorsByName: ({})
  property var monitorsById: ({})
  property string submap: ""
  // Quickshell keeps no focused monitor after the focused output is removed
  // (e.g. remote-display's headless output) until a focusedmon event, which
  // Hyprland skips when focus lands on the only monitor left. Fall back to
  // hyprctl's focused flag meanwhile. Use these instead of Hyprland.focusedMonitor.
  readonly property string focusedMonitorName: Hyprland.focusedMonitor?.name ?? root.monitors.find(monitor => monitor.focused)?.name ?? ""
  readonly property var focusedScreen: Quickshell.screens.find(s => s.name === root.focusedMonitorName) ?? null
  property int wsOffset: 0
  property bool clientsDirty: false
  property bool monitorsDirty: false
  property bool workspacesDirty: false
  property bool activeWorkspaceDirty: false
  property bool activeWindowDirty: false

  function rebuildClientIndexes() {
    root.clientsByAddress = root.clients.reduce((result, client) => (Object.assign(result, {
          [client.address]: client
        })), {});
    root.clientsByWorkspaceId = root.workspaces.reduce((result, workspace) => (Object.assign(result, {
          [workspace.id]: root.clients.filter(client => client.workspace.id === workspace.id)
        })), {});
    root.addresses = root.clients.map(client => client.address);
  }

  function scheduleRefresh(clients = false, monitors = false, workspaces = false, activeWorkspace = false, activeWindow = false) {
    root.clientsDirty = root.clientsDirty || clients;
    root.monitorsDirty = root.monitorsDirty || monitors;
    root.workspacesDirty = root.workspacesDirty || workspaces;
    root.activeWorkspaceDirty = root.activeWorkspaceDirty || activeWorkspace;
    root.activeWindowDirty = root.activeWindowDirty || activeWindow;
    debounceTimer.restart();
  }

  // hyprctl prints plain text instead of JSON while no monitor is focused
  function parseJson(text, fallback) {
    try {
      return JSON.parse(text);
    } catch (error) {
      return fallback;
    }
  }

  function updateAll() {
    root.scheduleRefresh(true, true, true, true, true);
  }

  Timer {
    id: debounceTimer

    interval: 50
    repeat: false
    onTriggered: {
      if (root.clientsDirty && !getClients.running) {
        root.clientsDirty = false;
        getClients.running = true;
      }
      if (root.monitorsDirty && !getMonitors.running) {
        root.monitorsDirty = false;
        getMonitors.running = true;
      }
      if (root.workspacesDirty && !getWorkspaces.running) {
        root.workspacesDirty = false;
        getWorkspaces.running = true;
      }
      if (root.activeWorkspaceDirty && !getActiveWorkspace.running) {
        root.activeWorkspaceDirty = false;
        getActiveWorkspace.running = true;
      }
      if (root.activeWindowDirty && !getActiveWindow.running) {
        root.activeWindowDirty = false;
        getActiveWindow.running = true;
      }
    }
  }

  Component.onCompleted: {
    root.updateAll();
  }

  // Quickshell drops focusedMonitor when the focused output is removed (e.g.
  // a headless output from remote-display) and only sets it again on a
  // focusedmon event, which Hyprland skips when focus lands on the only
  // monitor left. Re-query until a monitor is focused again.
  Timer {
    id: focusedMonitorRetry

    property int attempts: 0

    interval: 500
    repeat: true
    onTriggered: {
      if (Hyprland.focusedMonitor !== null || attempts >= 20) {
        stop();
        return;
      }
      attempts += 1;
      Hyprland.refreshMonitors();
    }
  }

  Connections {
    target: Hyprland

    function onFocusedMonitorChanged() {
      if (Hyprland.focusedMonitor === null && !focusedMonitorRetry.running) {
        focusedMonitorRetry.attempts = 0;
        focusedMonitorRetry.start();
      }
    }
  }

  Connections {
    target: Hyprland

    function onRawEvent(event) {
      if (event.name === "submap") {
        root.submap = event.data;
      } else if (event.name === "custom") {
        if (event.data) {
          const [key, value] = event.data.split(">>");
          if (key === "ws_offset") {
            root.wsOffset = parseInt(value);
          } else if (key === "harpoon_changed") {
            // window tags changed; hyprland emits no event for that
            root.scheduleRefresh(true);
          }
        }
      } else if (event.name === "activewindow" || event.name === "activewindowv2") {
        root.scheduleRefresh(false, false, true, false, true);
      } else if (event.name === "windowtitle" || event.name === "windowtitlev2") {
        root.scheduleRefresh(true, false, false, false, true);
      } else if (event.name === "openwindow" || event.name === "closewindow"
          || event.name === "movewindow" || event.name === "movewindowv2") {
        root.scheduleRefresh(true, false, true, false, true);
      } else if (event.name === "fullscreen" || event.name === "changefloatingmode"
          || event.name === "pin" || event.name === "urgent") {
        root.scheduleRefresh(true, false, false, false, true);
      } else if (event.name === "workspace" || event.name === "workspacev2"
          || event.name === "focusedmon" || event.name === "activespecial"
          || event.name === "activespecialv2") {
        root.scheduleRefresh(false, true, true, true, true);
      } else if (event.name === "createworkspace" || event.name === "createworkspacev2"
          || event.name === "destroyworkspace" || event.name === "destroyworkspacev2"
          || event.name === "moveworkspace" || event.name === "moveworkspacev2"
          || event.name === "renameworkspace") {
        root.scheduleRefresh(true, true, true, true, false);
      } else if (event.name === "monitoradded" || event.name === "monitoraddedv2"
          || event.name === "monitorremoved" || event.name === "configreloaded") {
        root.updateAll();
      }
    }
  }

  Process {
    id: getClients

    command: ["hyprctl", "clients", "-j"]
    stdout: StdioCollector {
      id: clientsCollector
      onStreamFinished: {
        root.clients = root.parseJson(clientsCollector.text, root.clients);
        root.rebuildClientIndexes();
      }
    }
    onExited: {
      if (root.clientsDirty)
        debounceTimer.restart();
    }
  }

  Process {
    id: getMonitors

    command: ["hyprctl", "monitors", "-j"]
    stdout: StdioCollector {
      id: monitorsCollector
      onStreamFinished: {
        root.monitors = root.parseJson(monitorsCollector.text, root.monitors);
        root.monitorsById = root.monitors.reduce((result, monitor) => (Object.assign(result, {
              [monitor.id]: monitor
            })), {});
        root.monitorsByName = root.monitors.reduce((result, monitor) => (Object.assign(result, {
              [monitor.name]: monitor
            })), {});
      }
    }
    onExited: {
      if (root.monitorsDirty)
        debounceTimer.restart();
    }
  }

  Process {
    id: getWorkspaces

    command: ["hyprctl", "workspaces", "-j"]
    stdout: StdioCollector {
      id: workspacesCollector
      onStreamFinished: {
        root.workspaces = root.parseJson(workspacesCollector.text, root.workspaces);
        root.workspacesById = root.workspaces.reduce((result, workspace) => (Object.assign(result, {
              [workspace.id]: workspace
            })), {});
        root.workspacesIds = root.workspaces.map(workspace => workspace.id);
        root.rebuildClientIndexes();
      }
    }
    onExited: {
      if (root.workspacesDirty)
        debounceTimer.restart();
    }
  }

  Process {
    id: getActiveWorkspace

    command: ["hyprctl", "activeworkspace", "-j"]
    stdout: StdioCollector {
      id: activeWorkspaceCollector
      onStreamFinished: {
        const _activeWorkspace = root.parseJson(activeWorkspaceCollector.text, null);
        root.activeWorkspace = _activeWorkspace?.monitor ? _activeWorkspace : null;
      }
    }
    onExited: {
      if (root.activeWorkspaceDirty)
        debounceTimer.restart();
    }
  }

  Process {
    id: getActiveWindow

    command: ["hyprctl", "activewindow", "-j"]
    stdout: StdioCollector {
      id: activeWindowCollector
      onStreamFinished: {
        const _activeWindow = root.parseJson(activeWindowCollector.text, null);
        root.activeWindow = _activeWindow?.address ? _activeWindow : null;
      }
    }
    onExited: {
      if (root.activeWindowDirty)
        debounceTimer.restart();
    }
  }
}
