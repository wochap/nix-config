import QtQuick
import qs.config
import qs.widgets.common

// hint bar of keycaps, e.g. [{ key: "Esc", text: "close" }]
Flow {
  id: root

  property var hints: []
  property color textColor: Theme.options.subtext0
  property color keycapBorder: Theme.options.overlay0

  spacing: 10

  Repeater {
    model: root.hints

    Row {
      id: hint

      required property var modelData

      spacing: 4

      StyledRect {
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: keyText.implicitWidth + 8
        implicitHeight: 16
        radius: Styles.radius.small
        border.width: 1
        border.color: root.keycapBorder

        StyledText {
          id: keyText

          anchors.centerIn: parent
          text: hint.modelData.key
          color: root.textColor
          font.pixelSize: Styles.font.pixelSize.smaller
          font.weight: Font.Medium
        }
      }

      StyledText {
        anchors.verticalCenter: parent.verticalCenter
        text: hint.modelData.text
        color: root.textColor
        font.pixelSize: Styles.font.pixelSize.smaller
      }
    }
  }
}
