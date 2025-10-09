import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Qt5Compat.GraphicalEffects
import qs.config
import qs.services
import qs.services.SNotifications
import qs.widgets.common
import qs.widgets.ControlCenter.widgets

PanelWindow {
  id: root

  WlrLayershell.namespace: "quickshell:control-center"
  WlrLayershell.layer: WlrLayer.Overlay
  anchors {
    top: true
    left: true
    bottom: true
    right: true
  }
  exclusionMode: ExclusionMode.Normal
  exclusiveZone: 0
  color: "transparent"
  mask: Region {
    item: rectangle
  }

  StyledRectangularShadow {
    target: rectangle
  }

  WrapperRectangle {
    id: rectangle

    anchors {
      top: parent.top
      right: parent.right
      topMargin: 8
      rightMargin: 8
    }
    radius: Styles.radius.windowRounding
    color: Theme.options.backgroundOverlay
    border {
      width: 1
      color: Theme.options.borderSecondary
    }
    margin: ConfigControlCenter.controlCenterPadding
    implicitWidth: ConfigControlCenter.controlCenterWidth

    child: ColumnLayout {
      spacing: ConfigControlCenter.controlCenterSpacing

      RowLayout {
        Layout.fillWidth: true

        ControlCenterButton {
          Layout.fillWidth: true
          Layout.preferredWidth: 1
          label: SNetwork.wifiLabel
          systemIcon: SNetwork.wifiIcon
          isActive: SNetwork.wifi.powered
          onClicked: {
            Quickshell.execDetached({
              command: ["shell-network", "--toggle-wifi"]
            });
          }
        }

        ControlCenterButton {
          Layout.fillWidth: true
          Layout.preferredWidth: 1
          label: SBluetooth.label
          materialIcon: SBluetooth.icon
          isActive: SBluetooth.powered
          onClicked: {
            Quickshell.execDetached({
              command: ["shell-bluetooth", "--toggle"]
            });
          }
        }

        ControlCenterButton {
          Layout.fillWidth: true
          Layout.preferredWidth: 1
          label: "Silent mode"
          woosIcon: ""
          isActive: SNotifications.isSilent
          onClicked: {
            SNotifications.toggleIsSilent();
          }
        }
      }

      RowLayout {
        Layout.fillWidth: true

        ControlCenterButton {
          Layout.fillWidth: true
          Layout.preferredWidth: 1
          label: "Night light"
          materialIcon: "moon_stars"
          isActive: SHyprsunset.active
          onClicked: {
            SHyprsunset.toggle();
          }
        }

        ControlCenterButton {
          Layout.fillWidth: true
          Layout.preferredWidth: 1
          label: "Bedtime mode"
          materialIcon: "filter_b_and_w"
          isActive: SHyprshade.isGrayScaleActive
          onClicked: {
            SHyprshade.toggleGrayScale();
          }
        }

        ControlCenterButton {
          Layout.fillWidth: true
          Layout.preferredWidth: 1
          label: "Dark mode"
          materialIcon: "dark_mode"
          isActive: STheme.isDarkModeActive
          onClicked: {
            STheme.toggleDarkMode();
          }
        }
      }

      HyprsunsetField {}

      BacklightField {}
    }
  }
}
