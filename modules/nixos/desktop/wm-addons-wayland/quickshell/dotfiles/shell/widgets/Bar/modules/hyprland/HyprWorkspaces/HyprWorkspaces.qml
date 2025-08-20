pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects

import qs.widgets.common
import qs.config
import qs.widgets.Bar.config
import qs.services

RowLayout {
  id: root

  readonly property int workspacesShown: 9
  property HyprlandMonitor monitor: Hyprland.monitorFor(root.QsWindow.window?.screen)
  property list<bool> workspaceOccupied: Array.from({
    length: root.workspacesShown
  }, (_, i) => {
    return Hyprland.workspaces.values.some(workspace => workspace.id === i + 1);
  })

  spacing: ConfigBar.modulesSpacing

  Repeater {
    model: root.workspacesShown

    delegate: HyprWorkspace {
      workspace: modelData
      monitor: root.monitor
      occupied: root.workspaceOccupied?.[index] ?? true
    }
  }
}
