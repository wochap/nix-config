import Quickshell
import Quickshell.Hyprland
import QtQuick
import qs.config
import qs.services
import qs.widgets.common
import qs.widgets.VBar.config

Loader {
  id: root

  property HyprlandMonitor hyprlandMonitor: Hyprland.monitorFor(QsWindow.window?.screen)
  property var workspaceId: hyprlandMonitor?.activeWorkspace?.id
  property var workspace: SHyprland.workspacesById[workspaceId]
  property var clients: SHyprland.clientsByWorkspaceId[workspaceId]?.filter?.(window => !window.floating)
  property int windowsCount: clients?.length ?? 0
  property bool isMonocle: workspace?.tiledLayout === "monocle"

  active: isMonocle
  visible: isMonocle
  sourceComponent: Component {
    Item {
      implicitWidth: 36
      implicitHeight: Math.max(22, labelText.implicitHeight + 4)

      StyledText {
        id: labelText

        anchors.centerIn: parent
        text: `[${root.windowsCount > 0 ? root.windowsCount : "M"}]`
        color: Theme.options.yellow
        font.weight: 500
      }
    }
  }
}
