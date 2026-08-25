import QtQuick
import qs.config
import qs.widgets.common

Rectangle {
  id: root

  required property string label

  implicitHeight: keyLabel.implicitHeight + 2 * ConfigWhichKeys.keycapPadding
  implicitWidth: Math.max(implicitHeight, keyLabel.implicitWidth + 2 * ConfigWhichKeys.keycapPadding)
  radius: 4
  color: Theme.options.surface0
  border {
    width: 1
    color: Theme.options.surface2
  }

  StyledText {
    id: keyLabel

    anchors.centerIn: parent
    text: root.label
    color: Theme.options.primary
    font.pixelSize: Styles.font.pixelSize.small
    font.weight: Font.DemiBold
  }
}
