import QtQuick
import qs.config
import qs.widgets.common
import qs.widgets.AuthPrompt

StyledRect {
  id: root

  required property string label
  property color textColor: ConfigAuth.subtext

  implicitWidth: text.implicitWidth + 10
  implicitHeight: text.implicitHeight + 2
  radius: ConfigAuth.smallRadius
  border.width: 1
  border.color: ConfigAuth.fieldBorder

  StyledText {
    id: text

    anchors.centerIn: parent
    text: root.label
    color: root.textColor
    font.pixelSize: ConfigAuth.keycapSize
    font.weight: Font.Medium
  }
}
