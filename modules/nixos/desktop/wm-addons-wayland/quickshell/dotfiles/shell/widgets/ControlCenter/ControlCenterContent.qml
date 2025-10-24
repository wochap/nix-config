import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
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

  property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
  property var hyprlandMonitor: SHyprland.monitorsByName?.[focusedScreen?.name] ?? null
  property var focusedWorkspace: SHyprland.workspacesById?.[hyprlandMonitor?.activeWorkspace?.id] ?? null
  property var focusedClient: SHyprland.clientsByAddress?.[focusedWorkspace?.lastwindow] ?? null
  property bool isFocusedClientFullScreen: (focusedClient?.fullscreen ?? null) === 2

  WlrLayershell.namespace: "quickshell:control-center"
  WlrLayershell.layer: WlrLayer.Overlay
  anchors {
    top: true
    left: true
    bottom: true
    right: true
  }
  exclusionMode: isFocusedClientFullScreen ? ExclusionMode.Ignore : ExclusionMode.Normal
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
      spacing: ConfigControlCenter.controlCenterSpacing * 2

      ColumnLayout {
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
              SNetwork.toggleWifiPower();
            }
          }

          ControlCenterButton {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            label: SBluetooth.label
            materialIcon: SBluetooth.icon
            isActive: SBluetooth.powered
            onClicked: {
              SBluetooth.togglePower();
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
            label: "Dark mode"
            materialIcon: "dark_mode"
            isActive: STheme.isDarkModeActive
            onClicked: {
              STheme.toggleDarkMode();
            }
          }

          ControlCenterButton {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            label: "Docker"
            woosIcon: ""
            isActive: SDocker.isActive
            onClicked: {
              SDocker.toggle();
            }
          }
        }

        RowLayout {
          Layout.fillWidth: true

          ControlCenterButton {
            Component.onCompleted: {
              SLegionBatteryConservation.getState();
            }

            Layout.fillWidth: true
            Layout.preferredWidth: 1
            label: "Charge Limit"
            woosIcon: "󱞜"
            isActive: SLegionBatteryConservation.isActive
            onClicked: {
              SLegionBatteryConservation.toggle();
            }
          }

          ControlCenterButton {
            Component.onCompleted: {
              SBatterySaver.getState();
            }

            Layout.fillWidth: true
            Layout.preferredWidth: 1
            label: "Battery saver"
            materialIcon: "eco"
            isActive: SBatterySaver.isActive
            onClicked: {
              SBatterySaver.toggle();
            }
          }

          ControlCenterButton {
            Component.onCompleted: {
              SLegionRapidCharging.getState();
            }

            Layout.fillWidth: true
            Layout.preferredWidth: 1
            label: "Rapid Charging"
            woosIcon: "󰂄"
            isActive: SLegionRapidCharging.isActive
            onClicked: {
              SLegionRapidCharging.toggle();
            }
          }
        }

        RowLayout {
          Layout.fillWidth: true

          ControlCenterButton {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            label: "Gray filter"
            materialIcon: "filter_b_and_w"
            isActive: SHyprshade.isGrayScaleActive
            onClicked: {
              SHyprshade.toggleGrayScale();
            }
          }

          ControlCenterButton {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            label: "OLED filter"
            materialIcon: "blur_on"
            isActive: SHyprshade.isOledSaverActive
            onClicked: {
              SHyprshade.toggleOledSaver();
            }
          }

          Item {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
          }
        }
      }

      ColumnLayout {
        spacing: ConfigControlCenter.controlCenterSpacing

        HyprsunsetField {}

        BacklightField {}

        OutputField {}

        InputField {}
      }

      PowerProfilesField {
        Layout.fillWidth: true
      }

      Battery {}
    }
  }
}
