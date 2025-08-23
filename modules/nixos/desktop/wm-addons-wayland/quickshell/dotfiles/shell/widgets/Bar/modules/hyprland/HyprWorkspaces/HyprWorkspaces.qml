import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import qs.config
import qs.widgets.common
import qs.widgets.Bar.config
import qs.services

import "utils.js" as Utils

RowLayout {
  id: root

  readonly property int workspacesShown: 9
  property HyprlandMonitor monitor: Hyprland.monitorFor(QsWindow.window?.screen)
  property list<bool> workspaceOccupied: Array.from({
    length: root.workspacesShown
  }, (_, i) => {
    return Hyprland.workspaces.values.some(workspace => workspace.id === i + 1);
  })
  readonly property var clientsByWorkspaceId: {
    const _monitor = Hypr.monitorsById[monitor?.id ?? 0];
    const workspaces = Hypr.workspacesByMonitorId[_monitor?.id ?? 0];
    if (!workspaces?.length) {
      return {};
    }
    const result = workspaces.reduce((result, workspace) => {
      const clients = (Hypr.clientsByWorkspaceId?.[workspace.id] ?? []).map(client => (Object.assign(client, {
            focused: client.address === Hypr.activeWindow?.address,
            customClass: Utils.mapAppId(client.class)
          })));
      return Object.assign(result, {
        [workspace.id]: clients
      });
    }, {});
    return result;
  }

  spacing: ConfigBar.modulesSpacing

  Repeater {
    model: root.workspacesShown

    delegate: HyprWorkspace {
      Layout.fillHeight: true

      workspace: modelData
      monitor: root.monitor
      occupied: root.workspaceOccupied?.[index] ?? true
      taskBarItems: root.clientsByWorkspaceId?.[index + 1] ?? []
    }
  }
}
