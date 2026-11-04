import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.widgets.common

PopupWindow {
  id: root

  property bool shown: false
  property string icon: ""
  property string appId: ""
  property string title: ""
  property int iconSize: 28

  readonly property alias bubble: bubble
  readonly property real bubbleHeight: bubble.implicitHeight
  readonly property real bubbleWidth: bubble.implicitWidth

  implicitWidth: bubble.implicitWidth + 32
  implicitHeight: bubble.implicitHeight + 24
  visible: root.shown || fadeAnimation.running
  color: "transparent"
  mask: Region {}

  StyledRectangularShadow {
    target: bubble
    elevation: Styles.elevation.e1
    opacity: bubble.opacity
  }

  StyledRect {
    id: bubble

    x: 16
    y: 12
    implicitWidth: bubbleCol.implicitWidth + 20
    implicitHeight: bubbleCol.implicitHeight + 14
    radius: 8
    color: Theme.options.base
    border.width: 1
    border.color: Theme.options.surface0
    opacity: root.shown ? 1 : 0

    Behavior on opacity {
      NumberAnimation {
        id: fadeAnimation
        duration: 150
        easing.type: Easing.InOutQuad
      }
    }

    RowLayout {
      id: bubbleCol

      anchors.centerIn: parent
      spacing: 10

      SystemIcon {
        Layout.alignment: Qt.AlignVCenter
        icon: root.icon
        size: root.iconSize
      }

      ColumnLayout {
        Layout.alignment: Qt.AlignVCenter
        spacing: 2

        StyledText {
          text: root.appId
          color: Theme.options.primary
          font.pixelSize: 10
          font.weight: 600
          visible: text.length > 0
        }

        StyledText {
          id: fullTitleText

          Layout.maximumWidth: 400
          text: root.title
          color: Theme.options.text
          font.pixelSize: 11
          elide: Text.ElideRight
          wrapMode: Text.WrapAnywhere
          visible: text.length > 0
        }
      }
    }
  }
}
