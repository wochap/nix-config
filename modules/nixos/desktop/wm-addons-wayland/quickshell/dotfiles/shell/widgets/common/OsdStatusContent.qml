import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config

PanelWindow {
  id: root

  property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
  property var service: null
  required property string serviceFlagKey
  property string namespace: ""
  property real flagValue: root.service[root.serviceFlagKey]
  property string iconOn: ""
  property string iconOff: ""
  property string materialIconOn: ""
  property string materialIconOff: ""

  WlrLayershell.namespace: root.namespace
  WlrLayershell.layer: WlrLayer.Overlay
  // TODO: add screen
  anchors {
    top: true
    left: true
    bottom: true
    right: true
  }
  screen: focusedScreen
  exclusionMode: ExclusionMode.Ignore
  exclusiveZone: 0
  color: "transparent"
  mask: Region {}

  StyledRectangularShadow {
    target: osd
  }

  Rectangle {
    id: osd

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Styles.font.pixelSize.normal * 2
    implicitWidth: 150
    implicitHeight: osd.implicitWidth
    radius: Styles.radius.windowRounding
    color: Theme.addAlpha(Theme.options.backgroundOverlay, Global.isBlurEnabled ? 0.65 : 1)
    border {
      width: 1
      color: Theme.options.borderSecondary
    }

    WoosIcon {
      visible: root.iconOn.length > 0
      anchors.centerIn: parent
      color: Theme.options.peach
      size: osd.width / 1.25
      icon: root.flagValue ? root.iconOn : root.iconOff
    }

    MaterialIcon {
      visible: root.materialIconOn.length > 0
      anchors.centerIn: parent
      color: Theme.options.peach
      size: osd.width / 1.2
      icon: root.flagValue ? root.materialIconOn : root.materialIconOff
      weight: Font.Normal
    }
  }
}
