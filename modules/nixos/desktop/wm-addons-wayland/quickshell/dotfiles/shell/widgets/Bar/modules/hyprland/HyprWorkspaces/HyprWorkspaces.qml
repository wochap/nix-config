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

  // readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.QsWindow.window?.screen)

  spacing: ConfigBar.modulesSpacing

  Repeater {
    model: 9

    delegate: HyprWorkspace {}
  }
}
