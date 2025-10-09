import QtQuick
import QtQuick.Controls
import qs.config

Slider {
  id: root

  property real radius: 2
  property real handleSize: 20
  property real backgroundHeight: 4

  topPadding: handleSize / 2
  bottomPadding: handleSize / 2
  leftPadding: 0
  rightPadding: 0

  background: Rectangle {
    x: root.leftPadding
    y: root.topPadding + root.availableHeight / 2 - height / 2
    anchors {
      left: parent.left
      right: parent.right
      verticalCenter: parent.verticalCenter
    }
    height: root.backgroundHeight
    radius: root.radius
    color: Theme.options.surface1

    Rectangle {
      width: root.visualPosition * parent.width
      height: parent.height
      radius: root.radius
      color: Theme.options.primary
    }
  }

  handle: Rectangle {
    width: root.handleSize
    height: root.handleSize
    radius: root.handleSize / 2
    color: Theme.options.text
    x: root.visualPosition * (parent.width) - width / 2
  }
}
