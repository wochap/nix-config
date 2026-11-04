import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import qs.config
import qs.services
import qs.widgets.common
import qs.widgets.VBar.config
import qs.widgets.VBar

PanelWindow {
  id: root

  required property ShellScreen modelData
  property HyprlandMonitor hyprlandMonitor: Hyprland.monitorFor(rectangle.QsWindow.window?.screen)
  property bool isFocused: root.modelData?.name === SHyprland.focusedMonitorName

  WlrLayershell.namespace: "quickshell:vbar"
  readonly property string namespace: WlrLayershell.namespace
  WlrLayershell.layer: WlrLayer.Bottom
  anchors {
    top: true
    bottom: true
    left: true
  }
  screen: root.modelData ?? null
  implicitWidth: ConfigVBar.barWidth + ConfigVBar.shadowWidth
  exclusiveZone: ConfigVBar.barWidth
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
      top: parent.top
      bottom: parent.bottom
    }
    implicitWidth: ConfigVBar.barWidth
    color: Theme.addAlpha(Theme.options.background, ConfigVBar.isBlurEnabled ? 0.65 : 1)

    Item {
      id: contentContainer

      anchors {
        fill: parent
        topMargin: ConfigVBar.barPaddingY
        bottomMargin: ConfigVBar.barPaddingY
        leftMargin: ConfigVBar.barPaddingX
        rightMargin: ConfigVBar.barPaddingX
      }

      VBarPanelTop {
        id: panelTop

        isFocused: root.isFocused
        width: contentContainer.width
        anchors {
          top: contentContainer.top
          horizontalCenter: contentContainer.horizontalCenter
        }
      }

      VBarPanelCenter {
        id: panelCenter

        isFocused: root.isFocused
        width: contentContainer.width
        anchors.horizontalCenter: contentContainer.horizontalCenter
        y: Math.max(panelTop.y + panelTop.height + ConfigVBar.modulesSpacing,
                    Math.round((contentContainer.height - height) / 2))
      }

      VBarPanelBottom {
        id: panelBottom

        isFocused: root.isFocused
        width: contentContainer.width
        anchors {
          bottom: contentContainer.bottom
          horizontalCenter: contentContainer.horizontalCenter
        }
      }
    }
  }
}
