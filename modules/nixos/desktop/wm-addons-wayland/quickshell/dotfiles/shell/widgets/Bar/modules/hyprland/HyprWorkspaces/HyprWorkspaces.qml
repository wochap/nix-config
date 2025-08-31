import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.config
import qs.widgets.common
import qs.widgets.Bar.config
import qs.services
import "../Utils.js" as Utils

RowLayout {
  id: root

  readonly property int workspacesShown: 9
  readonly property HyprlandMonitor monitor: Hyprland.monitorFor(QsWindow.window?.screen)
  readonly property list<bool> workspacesOccupied: Array.from({
    length: root.workspacesShown
  }, (_, i) => {
    return Hyprland.workspaces.values.some(workspace => workspace.id === i + 1);
  })
  readonly property var clientsByWorkspaceId: {
    const result = Object.entries(SHyprland.workspacesById).reduce((result, [workspaceId, workspace]) => {
      const clients = (SHyprland.clientsByWorkspaceId?.[workspace.id] ?? []).map(client => (Object.assign(client, {
            focused: client.address === SHyprland.activeWindow?.address,
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
      workspace: SHyprland.workspacesById[index + 1]
      monitor: root.monitor
      occupied: root.workspacesOccupied?.[index] ?? true
      clients: root.clientsByWorkspaceId?.[index + 1] ?? []
    }
  }
}
