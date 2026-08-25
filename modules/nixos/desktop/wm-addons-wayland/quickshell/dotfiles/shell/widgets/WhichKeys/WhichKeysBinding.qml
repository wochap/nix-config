import QtQuick
import QtQuick.Layouts
import qs.config
import qs.widgets.common

Item {
  id: root

  required property var keycaps
  required property string description

  implicitWidth: ConfigWhichKeys.minimumCellWidth
  implicitHeight: bindingRow.implicitHeight

  RowLayout {
    id: bindingRow

    x: ConfigWhichKeys.keyLaneWidth - keycapsRow.implicitWidth
    anchors.verticalCenter: parent.verticalCenter
    spacing: 8

    RowLayout {
      id: keycapsRow

      spacing: ConfigWhichKeys.keycapSpacing

      Repeater {
        model: root.keycaps

        delegate: WhichKeysKeycap {
          required property string modelData

          label: modelData
        }
      }
    }

    Rectangle {
      id: descriptionPill

      Layout.maximumWidth: ConfigWhichKeys.maximumDescriptionWidth
      implicitWidth: Math.min(descriptionLabel.implicitWidth + 12, ConfigWhichKeys.maximumDescriptionWidth)
      implicitHeight: descriptionLabel.implicitHeight + 4
      radius: 4
      color: "transparent"

      StyledRectangularShadow {
        target: descriptionPill
        z: -1
        blur: 8
        spread: 1
        cached: false
      }

      StyledText {
        id: descriptionLabel

        anchors {
          fill: parent
          leftMargin: 6
          rightMargin: 6
        }
        text: root.description.startsWith("+") ? root.description.slice(1) : root.description
        color: root.description.startsWith("+") ? Theme.options.peach : Theme.options.text
        elide: Text.ElideRight
        font.pixelSize: Styles.font.pixelSize.small
        font.weight: Font.Bold
      }
    }
  }
}
