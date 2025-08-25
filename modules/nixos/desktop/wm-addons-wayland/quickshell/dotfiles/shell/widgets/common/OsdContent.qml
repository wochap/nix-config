import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.config

PanelWindow {
  id: root

  property var service: null
  required property string serviceValueKey
  property var serviceValueTransformer: value => value
  property string namespace: ""
  property real value: root.serviceValueTransformer(root.service[root.serviceValueKey])
  property real percentage: root.value % 100 === 0 && root.value !== 0 ? 100 : root.value % 100
  property bool isOverflowing: value > 100
  property string icon: ""

  WlrLayershell.namespace: root.namespace
  WlrLayershell.layer: WlrLayer.Overlay
  anchors.left: true
  margins.left: 8
  exclusionMode: ExclusionMode.Ignore
  exclusiveZone: 0
  implicitWidth: 40
  implicitHeight: root.implicitWidth * 4
  color: "transparent"
  mask: Region {}

  Rectangle {
    id: osd

    anchors.fill: parent
    radius: width / 4
    color: Theme.addAlpha(Theme.options.backgroundOverlay, Global.isBlurEnabled ? 0.65 : 1)
    border {
      width: 1
      color: Theme.options.border
    }

    Rectangle {
      id: osdWrapper

      property int offset: 2

      anchors {
        fill: osd
        margins: (osdWrapper.offset)
      }
      color: "transparent"

      Rectangle {
        id: progressBar

        anchors {
          left: parent.left
          right: parent.right
          bottom: parent.bottom
        }
        radius: osd.radius - osdWrapper.offset
        color: isOverflowing ? Theme.options.blue : Theme.options.lavender
        implicitHeight: parent.height * percentage / 100
      }
    }

    MaterialIcon {
      anchors.horizontalCenter: osd.horizontalCenter
      anchors.bottom: osd.bottom
      anchors.bottomMargin: size / 8
      color: percentage < 15 ? progressBar.color : Theme.options.backgroundOverlay
      size: osd.width / 1.5
      icon: root.icon
    }
  }
}
