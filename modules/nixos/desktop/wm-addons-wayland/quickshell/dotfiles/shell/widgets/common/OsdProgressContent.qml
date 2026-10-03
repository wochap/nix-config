import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config

// Vertical pill-in-pill progress OSD, left edge, vertically centered
PanelWindow {
  id: root

  property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
  property var service: null
  required property string serviceValueKey
  property string serviceMutedKey: ""
  property var serviceValueTransformer: value => value
  property string namespace: ""
  property real value: root.serviceValueTransformer(root.service[root.serviceValueKey])
  property real percentage: Math.max(0, Math.min(100, root.value))
  property bool isOverflowing: root.value > 100
  property bool isMuted: root.serviceMutedKey.length > 0 && !!root.service[root.serviceMutedKey]
  property string icon: ""
  property string mutedIcon: ""
  property color fillColor: Theme.options.lavender
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

    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left
    anchors.leftMargin: 8
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

      property int padding: 4

      anchors.fill: parent
      implicitWidth: 44
      implicitHeight: 180
      radius: width / 2
      color: Theme.addAlpha(Theme.options.background, Global.isBlurEnabled ? 0.65 : 1)
      border {
        width: 1
        color: Theme.options.surface0
      }

      Rectangle {
        id: progressBar

        readonly property real trackHeight: osd.height - osd.padding * 2

        anchors {
          left: parent.left
          right: parent.right
          bottom: parent.bottom
          margins: osd.padding
        }
        radius: width / 2
        color: root.isMuted ? Theme.options.surface2 : root.isOverflowing ? Theme.options.peach : root.fillColor
        implicitHeight: Math.max(width, trackHeight * root.percentage / 100)

        Behavior on implicitHeight {
          animation: Styles.animations.numberAnimation.createObject(this)
        }
        Behavior on color {
          animation: Styles.animations.colorAnimation.createObject(this)
        }

        MaterialIcon {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 8
          color: Theme.options.crust
          size: Styles.font.pixelSize.larger
          weight: Font.Normal
          icon: root.isMuted && root.mutedIcon.length > 0 ? root.mutedIcon : root.icon
        }
      }
    }
  }
}
