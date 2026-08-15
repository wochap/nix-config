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
  readonly property HyprlandMonitor hyprlandMonitor: Hyprland.monitorFor(QsWindow.window?.screen)
  readonly property list<bool> workspacesOccupied: Array.from({
    length: root.workspacesShown
  }, (_, i) => {
    return Hyprland.workspaces.values.some(workspace => workspace.id === SHyprland.wsOffset + i + 1);
  })
  readonly property var clientsByWorkspaceId: {
    const result = Object.entries(SHyprland.workspacesById).reduce((result, [workspaceId, workspace]) => {
      const clients = (SHyprland.clientsByWorkspaceId?.[workspace.id] ?? []).map(client => (Object.assign(client, {
            isFocused: client.address === SHyprland.activeWindow?.address,
            customClass: Utils.mapAppId(client.class)
          }))).filter(client => !Utils.isIgnoredInWorkspaces(client.customClass, client.title));
      return Object.assign(result, {
        [workspace.id]: clients
      });
    }, {});
    return result;
  }

  Component.onCompleted: {
    Quickshell.execDetached(["bash", "-c", `hyprctl eval 'require("hyprland.lib.ws_offset").emit()'`]);
  }

  spacing: ConfigBar.modulesSpacing

  Repeater {
    model: root.workspacesShown
    delegate: HyprWorkspace {
      Layout.fillHeight: true
      clients: root.clientsByWorkspaceId?.[SHyprland.wsOffset + index + 1] ?? []
      workspace: SHyprland.workspacesById[SHyprland.wsOffset + index + 1]
      isOccupied: root.workspacesOccupied?.[index] ?? true
      hyprlandMonitor: root.hyprlandMonitor
    }
  }
}
