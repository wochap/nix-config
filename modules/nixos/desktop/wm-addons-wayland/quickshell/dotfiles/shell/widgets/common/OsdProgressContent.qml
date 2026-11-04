import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets.common

// Progress OSD: vertical pill on left edge (horizontal bar), or horizontal pill 6px off top (vertical bar)
PanelWindow {
  id: root

  property var focusedScreen: SHyprland.focusedScreen
  property var hyprlandMonitor: SHyprland.monitorsByName?.[focusedScreen?.name] ?? null
  property var focusedWorkspace: SHyprland.workspacesById?.[hyprlandMonitor?.activeWorkspace?.id] ?? null
  property var focusedClient: SHyprland.clientsByAddress?.[focusedWorkspace?.lastwindow] ?? null
  property bool isFocusedClientFullScreen: (focusedClient?.fullscreen ?? null) === 2
  readonly property real reservedTop: isFocusedClientFullScreen ? 0 : (hyprlandMonitor?.reserved?.[1] ?? 0)
  readonly property real reservedLeft: isFocusedClientFullScreen ? 0 : (hyprlandMonitor?.reserved?.[0] ?? 0)
  readonly property bool isHorizontal: Settings.options.renderVBar || (root.reservedLeft > 0 && root.reservedTop === 0)

  property var service: null
  required property string serviceValueKey
  property string serviceMutedKey: ""
  property var serviceValueTransformer: value => value
  property string namespace: ""
  property real value: root.serviceValueTransformer(root.service[root.serviceValueKey])
  property bool isOverflowing: root.value > 100
  // over-amplified values wrap around, e.g. 110 renders as 10% (in the overflow color)
  property real percentage: Math.max(0, Math.min(100, root.isOverflowing ? root.value - 100 : root.value))
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
      from: root.isHorizontal ? -Styles.animation.slideDistance : Styles.animation.slideDistance
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

    anchors.horizontalCenter: root.isHorizontal ? parent.horizontalCenter : undefined
    anchors.top: root.isHorizontal ? parent.top : undefined
    anchors.topMargin: root.isHorizontal ? 6 : 0
    anchors.verticalCenter: !root.isHorizontal ? parent.verticalCenter : undefined
    anchors.left: !root.isHorizontal ? parent.left : undefined
    anchors.leftMargin: !root.isHorizontal ? 8 : 0
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
      implicitWidth: root.isHorizontal ? 180 : 44
      implicitHeight: root.isHorizontal ? 44 : 180
      radius: Math.min(width, height) / 2
      color: Theme.options.background
      border {
        width: 1
        color: Theme.options.surface0
      }

      Rectangle {
        id: progressBar

        readonly property real trackLength: (root.isHorizontal ? osd.width : osd.height) - osd.padding * 2
        readonly property real capSize: (root.isHorizontal ? osd.height : osd.width) - osd.padding * 2

        anchors.top: root.isHorizontal ? parent.top : undefined
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: root.isHorizontal ? undefined : parent.right
        anchors.margins: osd.padding
        radius: capSize / 2
        color: root.isMuted ? Theme.options.surface2 : root.isOverflowing ? Theme.options.peach : root.fillColor

        implicitWidth: root.isHorizontal
          ? (capSize + Math.max(0, trackLength - capSize) * root.percentage / 100)
          : capSize
        implicitHeight: !root.isHorizontal
          ? (capSize + Math.max(0, trackLength - capSize) * root.percentage / 100)
          : capSize

        Behavior on implicitWidth {
          animation: Styles.animations.numberAnimation.createObject(this)
        }
        Behavior on implicitHeight {
          animation: Styles.animations.numberAnimation.createObject(this)
        }
        Behavior on color {
          animation: Styles.animations.colorAnimation.createObject(this)
        }

        Item {
          anchors.left: parent.left
          anchors.bottom: parent.bottom
          anchors.top: root.isHorizontal ? parent.top : undefined
          anchors.right: !root.isHorizontal ? parent.right : undefined
          width: progressBar.capSize
          height: progressBar.capSize

          SystemIcon {
            enableColoriser: true
            anchors.centerIn: parent
            color: Theme.options.crust
            size: Styles.font.pixelSize.hugeass
            icon: root.isMuted && root.mutedIcon.length > 0 ? root.mutedIcon : root.icon
          }
        }
      }
    }
  }
}
