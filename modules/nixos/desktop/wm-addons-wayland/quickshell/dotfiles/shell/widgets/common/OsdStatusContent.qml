import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config

// Square status tile, bottom-center
PanelWindow {
  id: root

  property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
  property var service: null
  required property string serviceFlagKey
  property string namespace: ""
  property bool flagValue: !!root.service[root.serviceFlagKey]
  property string iconOn: ""
  property string iconOff: ""
  property string systemIconOn: ""
  property string systemIconOff: ""
  property color colorOn: Theme.options.peach
  property color colorOff: Theme.options.text
  property bool isOpen: false

  signal exited

  function animateIn() {
    exitAnimation.stop();
    if (osdContainer.opacity === 0) {
      enterAnimation.restart();
    } else if (osdContainer.opacity < 1) {
      // re-opened while fading out: restore in place
      reenterAnimation.restart();
    }
  }

  onIsOpenChanged: {
    if (root.isOpen) {
      root.animateIn();
    } else {
      enterAnimation.stop();
      reenterAnimation.stop();
      exitAnimation.restart();
    }
  }
  Component.onCompleted: {
    if (root.isOpen)
      root.animateIn();
  }

  WlrLayershell.namespace: root.namespace
  WlrLayershell.layer: WlrLayer.Overlay
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

  ParallelAnimation {
    id: enterAnimation

    NumberAnimation {
      target: osdContainer
      property: "opacity"
      from: 0
      to: 1
      duration: Styles.animation.duration
      easing.type: Styles.animation.easingType
    }
    NumberAnimation {
      target: slide
      property: "y"
      from: Styles.animation.slideDistance
      to: 0
      duration: Styles.animation.duration
      easing.type: Styles.animation.easingType
    }
  }

  NumberAnimation {
    id: reenterAnimation

    target: osdContainer
    property: "opacity"
    to: 1
    duration: Styles.animation.duration
    easing.type: Styles.animation.easingType
  }

  NumberAnimation {
    id: exitAnimation

    target: osdContainer
    property: "opacity"
    to: 0
    duration: Styles.animation.exitDuration
    easing.type: Styles.animation.exitEasingType
    onFinished: root.exited()
  }

  Item {
    id: osdContainer

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 96
    implicitWidth: osd.implicitWidth
    implicitHeight: osd.implicitHeight
    opacity: 0
    transform: Translate {
      id: slide
    }

    StyledRectangularShadow {
      target: osd
      elevation: Styles.elevation.e2
    }

    Rectangle {
      id: osd

      anchors.fill: parent
      implicitWidth: 96
      implicitHeight: 96
      radius: Styles.radius.windowRounding
      color: Theme.addAlpha(Theme.options.background, Global.isBlurEnabled ? 0.65 : 1)
      border {
        width: 1
        color: Theme.options.surface0
      }

      WoosIcon {
        visible: root.iconOn.length > 0
        anchors.centerIn: parent
        color: root.flagValue ? root.colorOn : root.colorOff
        size: 44
        icon: root.flagValue ? root.iconOn : root.iconOff
      }

      SystemIcon {
        enableColoriser: true
        visible: root.systemIconOn.length > 0
        anchors.centerIn: parent
        color: root.flagValue ? root.colorOn : root.colorOff
        size: 44
        icon: root.flagValue ? root.systemIconOn : root.systemIconOff
      }
    }
  }
}
