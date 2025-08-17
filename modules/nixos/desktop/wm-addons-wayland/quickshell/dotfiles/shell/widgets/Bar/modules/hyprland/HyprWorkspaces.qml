import Quickshell
import QtQuick
import Quickshell.Wayland
import Quickshell.Hyprland

import qs.config

Item {
  id: root

  readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.QsWindow.window?.screen)
  readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
  readonly property int workspaceGroup: Math.floor((monitor?.activeWorkspace?.id - 1) / 9)
  property list<bool> workspaceOccupied: []
  property int workspaceIndexInGroup: (monitor?.activeWorkspace?.id - 1) % 9
  anchors.centerIn: parent

  Text {
    text: `123123asdasdasdashello worldsdad ${Paths.config}`
  }
}
