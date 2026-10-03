import QtQuick
import qs.config
import qs.widgets.common

// Empty state: no windows to show.
Item {
  id: root

  property string title: "No windows open"
  property string hint: ""

  implicitWidth: 420
  implicitHeight: 180

  Column {
    anchors.centerIn: parent
    spacing: 6

    MaterialIcon {
      anchors.horizontalCenter: parent.horizontalCenter
      icon: "select_window_off"
      size: 32
      color: Theme.options.surface1
    }

    StyledText {
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.title
      font.pixelSize: Styles.font.pixelSize.small
      color: Theme.options.subtext0
    }

    StyledText {
      anchors.horizontalCenter: parent.horizontalCenter
      visible: root.hint.length > 0
      text: root.hint
      font.pixelSize: Styles.font.pixelSize.smaller
      color: Theme.options.overlay1
    }
  }
}
