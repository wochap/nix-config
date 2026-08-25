import QtQuick
import QtQuick.Layouts
import qs.config
import qs.widgets.common

RowLayout {
  id: root

  required property var keycaps
  required property string description

  spacing: 8

  RowLayout {
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
    Layout.fillWidth: true
    text: root.description
    elide: Text.ElideRight
  }
}
