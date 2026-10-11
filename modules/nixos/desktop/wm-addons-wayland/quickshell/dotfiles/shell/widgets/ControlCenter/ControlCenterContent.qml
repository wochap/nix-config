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
import qs.widgets.Media

PanelWindow {
  id: root

  property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
  property var hyprlandMonitor: SHyprland.monitorsByName?.[focusedScreen?.name] ?? null
  property var focusedWorkspace: SHyprland.workspacesById?.[hyprlandMonitor?.activeWorkspace?.id] ?? null
  property var focusedClient: SHyprland.clientsByAddress?.[focusedWorkspace?.lastwindow] ?? null
  property bool isFocusedClientFullScreen: (focusedClient?.fullscreen ?? null) === 2
  // space reserved by the bar, the window ignores exclusive zones so the
  // backdrop also covers the bar and a click there closes the panel
  readonly property real reservedTop: isFocusedClientFullScreen ? 0 : (hyprlandMonitor?.reserved?.[1] ?? 0)
  readonly property string bluetoothDevice: Bluetooth.devices.values.find(d => d.connected)?.name ?? ""

  screen: root.focusedScreen
  WlrLayershell.namespace: "quickshell:control-center"
  // read by qs.Woints SHints, the attached WlrLayershell is not reachable from JS
  readonly property string namespace: WlrLayershell.namespace
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: SControlCenter.isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  anchors {
    top: true
    left: true
    bottom: true
    right: true
  }
  exclusionMode: ExclusionMode.Ignore
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
    STailscale.getState();
    if (SUpower.available) {
      SLegionBatteryConservation.getState();
      SBatterySaver.getState();
      SLegionRapidCharging.getState();
    }
  }

  // click outside closes, including clicks on the bar (and on the bar
  // button that opened it, so it never closes and reopens)
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
      topMargin: root.reservedTop + ConfigControlCenter.controlCenterMargin
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
            iconSystem: SNetwork.wifi?.powered ? "network-wireless-signal-excellent" : "network-wireless-offline"
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
            iconSystem: SBluetooth.powered ? (root.bluetoothDevice ? "bluetooth-paired" : "bluetooth-active") : "bluetooth-disabled"
            label: "Bluetooth"
            sublabel: SBluetooth.powered ? (root.bluetoothDevice || "On") : "Off"
            isActive: SBluetooth.powered
            hasChevron: true
            onClicked: SBluetooth.togglePower()
            onChevronClicked: SControlCenter.openScratchpad("tui-bluetooth")
          }

          ControlCenterTile {
            Layout.fillWidth: true
            iconSystem: "notification-disabled"
            label: "Silent mode"
            isActive: SNotifications.isSilent
            onClicked: SNotifications.toggleIsSilent()
          }

          ControlCenterTile {
            Layout.fillWidth: true
            iconSystem: "night-light-symbolic"
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
            iconSystem: "security-high"
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
            iconSystem: "battery-good"
            label: "Charge limit"
            isActive: SLegionBatteryConservation.isActive
            onClicked: SLegionBatteryConservation.toggle()
          }

          ControlCenterTile {
            Layout.fillWidth: true
            visible: SUpower.available
            iconSystem: "battery-profile-powersave"
            label: "Battery saver"
            isActive: SBatterySaver.isActive
            onClicked: SBatterySaver.toggle()
          }

          ControlCenterTile {
            Layout.fillWidth: true
            visible: SUpower.available
            iconSystem: "battery-profile-performance"
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
            icon: "keyboard"
            label: "Keyboard"
            isActive: SVirtualKeyboard.isActive
            onClicked: SVirtualKeyboard.toggle()
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

          ControlCenterTile {
            Layout.fillWidth: true
            visible: STailscale.available
            icon: "vpn_lock"
            label: "Tailnet"
            sublabel: STailscale.needsLogin ? "Not logged in" : STailscale.isActive ? STailscale.ip : "Disconnected"
            isActive: STailscale.isActive
            onClicked: STailscale.toggle()
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: ConfigControlCenter.sliderSpacing

          SliderField {
            Layout.fillWidth: true
            icon: "night-light-symbolic"
            minimum: 3000
            maximum: 6500
            step: 100
            value: SHyprsunset.temperature
            valueText: `${displayValue}K`
            tooltipText: `${displayValue}`
            fillColor: SHyprsunset.active ? Theme.options.peach : Theme.options.surface2
            isButtonInteractive: true
            buttonLabel: SHyprsunset.active ? "Turn off night light" : "Turn on night light"
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
            icon: "display-brightness"
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
            icon: SPipewire.isOutputMuted ? "audio-volume-muted" : displayValue === 0 ? "audio-volume-low-zero-panel" : displayValue < 50 ? "audio-volume-medium" : "audio-volume-high"
            minimum: 0
            maximum: 200
            step: 5
            overdriveFrom: 100
            value: Math.round(SPipewire.outputVolume * 100)
            isMuted: SPipewire.isOutputMuted
            valueText: SPipewire.isOutputMuted ? "muted" : `${displayValue}%`
            isButtonInteractive: true
            buttonLabel: SPipewire.isOutputMuted ? "Unmute output" : "Mute output"
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
            icon: SPipewire.isInputMuted ? "microphone-sensitivity-muted" : "microphone-sensitivity-high"
            minimum: 0
            maximum: 100
            step: 5
            value: Math.round(SPipewire.inputVolume * 100)
            isMuted: SPipewire.isInputMuted
            valueText: SPipewire.isInputMuted ? "muted" : `${displayValue}%`
            isButtonInteractive: true
            buttonLabel: SPipewire.isInputMuted ? "Unmute microphone" : "Mute microphone"
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
