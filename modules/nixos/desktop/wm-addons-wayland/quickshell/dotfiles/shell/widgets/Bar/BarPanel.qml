import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects

import qs.config
import qs.widgets.common
import qs.widgets.Bar.config
import qs.widgets.Bar.modules.hyprland.HyprWorkspaces

PanelWindow {
  id: root

  required property ShellScreen modelData

  WlrLayershell.namespace: "quickshell:bar"
  WlrLayershell.layer: WlrLayer.Bottom
  anchors {
    top: true
    left: true
    right: true
  }

  screen: root.modelData
  implicitHeight: ConfigBar.barHeight + ConfigBar.shadowHeight
  exclusiveZone: ConfigBar.barHeight
  color: "transparent"

  Rectangle {
    id: rectangle

    anchors {
      left: parent.left
      right: parent.right
      top: parent.top
    }

    height: ConfigBar.barHeight
    color: Theme.addAlpha(Theme.options.background, ConfigBar.isBlurEnabled ? 0.65 : 1)

    BarPanelLeft {}
    BarPanelCenter {}
    BarPanelRight {}
  }

  StyledRectangularShadow {
    target: rectangle
    z: -1
  }
}
