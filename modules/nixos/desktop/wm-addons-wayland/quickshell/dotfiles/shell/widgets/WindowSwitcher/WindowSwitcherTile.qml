import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.widgets.common

Item {
  id: tile

  property var captureSource: null
  property string title: ""
  property bool selected: false
  signal clicked

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: tile.clicked()
  }

  ColumnLayout {
    anchors {
      fill: parent
      topMargin: 10
      bottomMargin: 10
    }
    spacing: 10

    StyledRect {
      Layout.fillWidth: true
      Layout.fillHeight: true
      radius: Styles.radius.windowRounding
      color: Theme.options.surface0
      border {
        width: tile.selected ? 3 : 1.5
        color: tile.selected ? Theme.options.primary : Theme.options.borderSecondary
      }

      Behavior on border.color {
        animation: Styles.animations.colorAnimation.createObject(tile)
      }

      ScreencopyView {
        id: capture
        anchors {
          fill: parent
          margins: 8
        }
        clip: true
        captureSource: tile.captureSource
        live: true
        visible: tile.captureSource !== null
      }

      StyledText {
        anchors.centerIn: parent
        width: parent.width - 16
        visible: tile.captureSource === null || !capture.hasContent
        text: tile.title
        font.pixelSize: Styles.font.pixelSize.large
        elide: Text.ElideMiddle
        horizontalAlignment: Text.AlignHCenter
      }
    }

    StyledText {
      Layout.fillWidth: true
      Layout.preferredHeight: 18
      elide: Text.ElideMiddle
      horizontalAlignment: Text.AlignHCenter
      font.pixelSize: Styles.font.pixelSize.small
      color: tile.selected ? Theme.options.text : Theme.options.textDimmed
      text: tile.title
    }
  }
}
