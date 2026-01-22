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
  readonly property int maxContainerWidth: 1720

  WlrLayershell.namespace: "quickshell:bar"
  WlrLayershell.layer: WlrLayer.Bottom
  anchors {
    top: true
    left: true
    right: true
  }
  screen: root.modelData ?? null
  // HACK: add enough space for shadow
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

    Item {
      id: contentContainer

      width: Math.min(parent.width, root.maxContainerWidth)
      anchors {
        top: parent.top
        bottom: parent.bottom
        // Center the content "margin: 0 auto"
        horizontalCenter: parent.horizontalCenter
      }

      BarPanelLeft {
        isFocused: root.isFocused
        anchors {
          left: contentContainer.left // Anchor to the constrained wrapper
          leftMargin: ConfigBar.barPaddingX
          top: contentContainer.top
          topMargin: ConfigBar.barPaddingY
          bottom: contentContainer.bottom
          bottomMargin: ConfigBar.barPaddingY
        }
      }

      BarPanelCenter {
        anchors {
          horizontalCenter: contentContainer.horizontalCenter
          top: contentContainer.top
          topMargin: ConfigBar.barPaddingY
          bottom: contentContainer.bottom
          bottomMargin: ConfigBar.barPaddingY
        }
      }

      BarPanelRight {
        isFocused: root.isFocused
        anchors {
          right: contentContainer.right // Anchor to the constrained wrapper
          rightMargin: ConfigBar.barPaddingX
          top: contentContainer.top
          topMargin: ConfigBar.barPaddingY
          bottom: contentContainer.bottom
          bottomMargin: ConfigBar.barPaddingY
        }
      }
    }
  }
}
