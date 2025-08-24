import Quickshell
import Quickshell.Hyprland
import QtQuick

import qs.config
import qs.services
import qs.widgets.common
import qs.widgets.Bar.modules

Loader {
  id: root

  property HyprlandMonitor monitor: Hyprland.monitorFor(QsWindow.window?.screen)
  property var workspaceId: monitor?.activeWorkspace?.id
  property var workspace: Hypr.workspacesById[workspaceId]
  property var clients: Hypr.clientsByWorkspaceId[workspaceId]?.filter?.(window => !window.floating)
  property int windowsCount: clients?.length ?? 0
  property bool isMonocle: Hypr.monocleState[monitor?.name]?.includes?.(workspaceId) ?? false

  active: isMonocle
  visible: isMonocle
  sourceComponent: Component {
    Module {
      label: `[${windowsCount > 0 ? windowsCount : "M"}]`
      fgColor: Theme.options.yellow
    }
  }
}
