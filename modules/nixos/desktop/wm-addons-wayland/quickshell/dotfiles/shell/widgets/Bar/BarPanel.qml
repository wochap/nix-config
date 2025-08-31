import Quickshell
import Quickshell.Wayland
import QtQuick
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
  // HACK: add enought space for shadow
  implicitHeight: ConfigBar.barHeight + ConfigBar.shadowHeight
  exclusiveZone: ConfigBar.barHeight
  color: "transparent"

  StyledRectangularShadow {
    target: rectangle
  }

  Rectangle {
    id: rectangle

    anchors {
      left: parent.left
      right: parent.right
      top: parent.top
    }
    implicitHeight: ConfigBar.barHeight
    color: Theme.addAlpha(Theme.options.background, ConfigBar.isBlurEnabled ? 0.65 : 1)

    BarPanelLeft {
      anchors {
        left: rectangle.left
        leftMargin: ConfigBar.barPaddingX
        top: rectangle.top
        topMargin: ConfigBar.barPaddingY
        bottom: rectangle.bottom
        bottomMargin: ConfigBar.barPaddingY
      }
    }

    BarPanelCenter {
      anchors {
        horizontalCenter: rectangle.horizontalCenter
        top: rectangle.top
        topMargin: ConfigBar.barPaddingY
        bottom: rectangle.bottom
        bottomMargin: ConfigBar.barPaddingY
      }
    }

    BarPanelRight {
      anchors {
        right: rectangle.right
        rightMargin: ConfigBar.barPaddingX
        top: rectangle.top
        topMargin: ConfigBar.barPaddingY
        bottom: rectangle.bottom
        bottomMargin: ConfigBar.barPaddingY
      }
    }
  }
}
