import QtQuick
import QtQuick.Layouts
import qs.config
import qs.widgets.common

Item {
  id: root

  required property var keycaps
  required property string description

  implicitWidth: ConfigWhichKeys.minimumCellWidth
  implicitHeight: card.implicitHeight

  StyledRectangularShadow {
    target: card
    cached: false
  }

  Rectangle {
    id: card

    x: ConfigWhichKeys.keyLaneWidth - keycapsRow.implicitWidth
    anchors.verticalCenter: parent.verticalCenter
    implicitWidth: bindingRow.implicitWidth + 2 * ConfigWhichKeys.bindingPadding
    implicitHeight: bindingRow.implicitHeight + 2 * ConfigWhichKeys.bindingPadding
    radius: Styles.radius.windowRounding
    color: Theme.addAlpha(Theme.options.backgroundOverlay, ConfigWhichKeys.bindingBackgroundOpacity)
    border {
      width: 1
      color: Theme.options.borderSecondary
    }

    RowLayout {
      id: bindingRow

      anchors {
        fill: parent
        margins: ConfigWhichKeys.bindingPadding
      }
      spacing: 4

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

      StyledText {
        text: "→"
        color: Theme.options.textDimmed
        font.pixelSize: Styles.font.pixelSize.small
      }

      StyledText {
        Layout.maximumWidth: ConfigWhichKeys.maximumDescriptionWidth
        text: root.description
        elide: Text.ElideRight
        font.pixelSize: Styles.font.pixelSize.small
      }
    }
  }
}
