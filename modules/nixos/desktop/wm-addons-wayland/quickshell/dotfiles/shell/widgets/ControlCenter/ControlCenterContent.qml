pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Wayland
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
  readonly property string bluetoothDevice: Bluetooth.devices.values.find(d => d.connected)?.name ?? ""

  screen: root.focusedScreen
  WlrLayershell.namespace: "quickshell:control-center"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: SControlCenter.isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  anchors {
    top: true
    left: true
    bottom: true
    right: true
  }
  exclusionMode: isFocusedClientFullScreen ? ExclusionMode.Ignore : ExclusionMode.Normal
  exclusiveZone: 0
  color: "transparent"

  Component.onCompleted: {
    SSystemInfo.refresh();
    STheme.getState();
    SHyprsunset.getState();
    SHyprshade.getState();
    SFirewall.getState();
    SOllama.getState();
    SSupertonic.getState();
    SSandbox.getState();
    SDocker.getState();
    if (SUpower.available) {
      SLegionBatteryConservation.getState();
      SBatterySaver.getState();
      SLegionRapidCharging.getState();
    }
  }

  // click outside closes
  MouseArea {
    anchors.fill: parent
    enabled: SControlCenter.isOpen
    onClicked: SControlCenter.close()
  }

  Item {
    id: keyCatcher

    focus: true
    Keys.onEscapePressed: SControlCenter.close()
  }

  Item {
    id: container

    anchors {
      top: parent.top
      right: parent.right
      topMargin: ConfigControlCenter.controlCenterMargin
      rightMargin: ConfigControlCenter.controlCenterMargin
    }
    width: panel.width
    height: panel.height
    transformOrigin: Item.TopRight
    opacity: 0
    scale: 0.96
    transform: Translate {
      id: slide

      y: -Styles.animation.slideDistance
    }

    states: State {
      name: "open"
      when: SControlCenter.isOpen

      PropertyChanges {
        container.opacity: 1
        container.scale: 1
        slide.y: 0
      }
    }

    transitions: [
      Transition {
        to: "open"

        NumberAnimation {
          properties: "opacity,scale,y"
          duration: Styles.animation.duration
          easing.type: Styles.animation.easingType
        }
      },
      Transition {
        from: "open"

        SequentialAnimation {
          NumberAnimation {
            properties: "opacity,scale,y"
            duration: Styles.animation.exitDuration
            easing.type: Styles.animation.exitEasingType
          }

          ScriptAction {
            script: SControlCenter.finalizeClose()
          }
        }
      }
    ]

    StyledRectangularShadow {
      target: panel
      elevation: Styles.elevation.e2
    }

    StyledRect {
      id: panel

      width: ConfigControlCenter.controlCenterWidth
      height: column.implicitHeight + ConfigControlCenter.controlCenterPadding * 2
      radius: Styles.radius.windowRounding
      color: Theme.options.background
      border {
        width: 1
        color: Theme.options.surface0
      }

      // swallow clicks so they don't reach the backdrop
      MouseArea {
        anchors.fill: parent
      }

      ColumnLayout {
        id: column

        anchors {
          fill: parent
          margins: ConfigControlCenter.controlCenterPadding
        }
        spacing: ConfigControlCenter.controlCenterSpacing

        ControlCenterHeader {
          Layout.fillWidth: true
        }

        GridLayout {
          Layout.fillWidth: true
          columns: 2
          uniformCellWidths: true
          rowSpacing: ConfigControlCenter.tileSpacing
          columnSpacing: ConfigControlCenter.tileSpacing

          ControlCenterTile {
            Layout.fillWidth: true
            icon: SNetwork.wifi?.powered ? "wifi" : "wifi_off"
            label: "Wi-Fi"
            sublabel: SNetwork.wifi?.powered ? (SNetwork.wifi?.connected ? SNetwork.wifi.ssid : "Disconnected") : "Off"
            isActive: SNetwork.wifi?.powered ?? false
            enabled: SNetwork.wifi !== null
            hasChevron: true
            onClicked: SNetwork.toggleWifiPower()
            onChevronClicked: SControlCenter.openScratchpad("tui-wifi")
          }

          ControlCenterTile {
            Layout.fillWidth: true
            icon: SBluetooth.powered ? (root.bluetoothDevice ? "bluetooth_connected" : "bluetooth") : "bluetooth_disabled"
            label: "Bluetooth"
            sublabel: SBluetooth.powered ? (root.bluetoothDevice || "On") : "Off"
            isActive: SBluetooth.powered
            hasChevron: true
            onClicked: SBluetooth.togglePower()
            onChevronClicked: SControlCenter.openScratchpad("tui-bluetooth")
          }

          ControlCenterTile {
            Layout.fillWidth: true
            icon: "notifications_off"
            label: "Silent mode"
            isActive: SNotifications.isSilent
            onClicked: SNotifications.toggleIsSilent()
          }

          ControlCenterTile {
            Layout.fillWidth: true
            icon: "nightlight"
            label: "Night light"
            isActive: SHyprsunset.active
            onClicked: SHyprsunset.toggle()
          }

          ControlCenterTile {
            Layout.fillWidth: true
            icon: "dark_mode"
            label: "Dark mode"
            isActive: STheme.isDarkModeActive
            onClicked: STheme.toggleDarkMode()
          }

          ControlCenterTile {
            Layout.fillWidth: true
            icon: "chrome_reader_mode"
            label: "Reader mode"
            isActive: SHyprshade.isReaderActive
            onClicked: SHyprshade.toggleReader()
          }

          ControlCenterTile {
            Layout.fillWidth: true
            icon: "shield"
            label: "Firewall"
            isActive: SFirewall.isActive
            onClicked: SFirewall.toggle()
          }

          ControlCenterTile {
            Layout.fillWidth: true
            icon: "neurology"
            label: "Ollama"
            isActive: SOllama.isActive
            onClicked: SOllama.toggle()
          }

          ControlCenterTile {
            Layout.fillWidth: true
            icon: "record_voice_over"
            label: "Supertonic"
            isActive: SSupertonic.isActive
            onClicked: SSupertonic.toggle()
          }

          ControlCenterTile {
            Layout.fillWidth: true
            visible: SUpower.available
            icon: "battery_status_good"
            label: "Charge limit"
            isActive: SLegionBatteryConservation.isActive
            onClicked: SLegionBatteryConservation.toggle()
          }

          ControlCenterTile {
            Layout.fillWidth: true
            visible: SUpower.available
            icon: "battery_saver"
            label: "Battery saver"
            isActive: SBatterySaver.isActive
            onClicked: SBatterySaver.toggle()
          }

          ControlCenterTile {
            Layout.fillWidth: true
            visible: SUpower.available
            icon: "electric_bolt"
            label: "Rapid charging"
            isActive: SLegionRapidCharging.isActive
            onClicked: SLegionRapidCharging.toggle()
          }

          ControlCenterTile {
            Layout.fillWidth: true
            icon: "filter_b_and_w"
            label: "Gray filter"
            isActive: SHyprshade.isGrayScaleActive
            onClicked: SHyprshade.toggleGrayScale()
          }

          ControlCenterTile {
            Layout.fillWidth: true
            icon: "contrast"
            label: "OLED filter"
            isActive: SHyprshade.isOledSaverActive
            onClicked: SHyprshade.toggleOledSaver()
          }

          ControlCenterTile {
            Layout.fillWidth: true
            visible: SSandbox.available
            icon: "deployed_code"
            label: "Sandbox"
            isActive: SSandbox.isActive
            onClicked: SSandbox.toggle()
          }

          ControlCenterTile {
            Layout.fillWidth: true
            visible: SDocker.available
            icon: "sailing"
            label: "Docker"
            sublabel: SDocker.isActive ? "Running" : "Stopped"
            isActive: SDocker.isActive
            onClicked: SDocker.toggle()
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: ConfigControlCenter.sliderSpacing

          SliderField {
            Layout.fillWidth: true
            icon: "nightlight"
            minimum: 3000
            maximum: 6500
            step: 100
            value: SHyprsunset.temperature
            valueText: `${displayValue}K`
            tooltipText: `${displayValue}`
            fillColor: SHyprsunset.active ? Theme.options.peach : Theme.options.surface2
            isButtonInteractive: true
            onButtonClicked: SHyprsunset.toggle()
            onMoved: value => {
              if (value > 0) {
                SHyprsunset.setTemperature(value);
              }
            }
          }

          SliderField {
            Layout.fillWidth: true
            visible: SBacklight.available
            icon: "brightness_6"
            minimum: 0
            maximum: 100
            step: 5
            value: SBacklight.percentage
            onMoved: value => SBacklight.set(value)
          }

          SliderField {
            readonly property var audio: SPipewire.defaultSink?.audio ?? null

            Layout.fillWidth: true
            enabled: SPipewire.outputReady
            icon: SPipewire.isOutputMuted ? "volume_off" : displayValue === 0 ? "volume_mute" : displayValue < 50 ? "volume_down" : "volume_up"
            minimum: 0
            maximum: 150
            step: 5
            overdriveFrom: 100
            value: Math.round(SPipewire.outputVolume * 100)
            isMuted: SPipewire.isOutputMuted
            valueText: SPipewire.isOutputMuted ? "muted" : `${displayValue}%`
            isButtonInteractive: true
            onButtonClicked: {
              if (audio) {
                audio.muted = !audio.muted;
              }
            }
            onMoved: value => SPipewire.setOutputVolume(value)
          }

          SliderField {
            readonly property var audio: SPipewire.defaultSource?.audio ?? null

            Layout.fillWidth: true
            enabled: SPipewire.inputReady
            icon: SPipewire.isInputMuted ? "mic_off" : "mic"
            minimum: 0
            maximum: 100
            step: 5
            value: Math.round(SPipewire.inputVolume * 100)
            isMuted: SPipewire.isInputMuted
            valueText: SPipewire.isInputMuted ? "muted" : `${displayValue}%`
            isButtonInteractive: true
            onButtonClicked: {
              if (audio) {
                audio.muted = !audio.muted;
              }
            }
            onMoved: value => SPipewire.setInputVolume(value)
          }
        }

        PowerProfilesField {
          Layout.fillWidth: true
          visible: SPowerProfiles.list.length > 0
        }

        BatteryCard {
          Layout.fillWidth: true
          visible: SUpower.available
        }

        MediaCard {
          Layout.fillWidth: true
          visible: SMpris.available
        }
      }
    }
  }
}
