import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import qs.config
import qs.widgets.common
import qs.widgets.Bar.config
import qs.widgets.Bar.modules.Hyprland.HyprWorkspaces

PanelWindow {
  id: root

  required property ShellScreen modelData
  property HyprlandMonitor hyprlandMonitor: Hyprland.monitorFor(rectangle.QsWindow.window?.screen)
  property bool isFocused: hyprlandMonitor?.id === Hyprland.focusedMonitor?.id

  WlrLayershell.namespace: "quickshell:bar"
  WlrLayershell.layer: WlrLayer.Bottom
  anchors {
    top: true
    left: true
    right: true
  }
  screen: root.modelData ?? null
  // HACK: add enought space for shadow
  implicitHeight: ConfigBar.barHeight + ConfigBar.shadowHeight
  exclusiveZone: ConfigBar.barHeight
  color: "transparent"
  mask: Region {
    item: rectangle
  }

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
      isFocused: root.isFocused
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
      isFocused: root.isFocused
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
