import QtQuick
import QtQuick.Layouts
import qs.config
import qs.widgets.common
import qs.widgets.AuthPrompt

// glyph + words, color is never the only signal
RowLayout {
  id: root

  required property string icon
  required property string text
  property color iconColor: ConfigAuth.subtext
  property color textColor: ConfigAuth.subtext
  property real iconFill: 1

  spacing: 8

  MaterialIcon {
    Layout.alignment: Qt.AlignTop
    icon: root.icon
    size: 16
    fill: root.iconFill
    color: root.iconColor
  }

  StyledText {
    Layout.fillWidth: true
    text: root.text
    color: root.textColor
    wrapMode: Text.Wrap
    font.pixelSize: ConfigAuth.metaSize
    lineHeight: 16
    lineHeightMode: Text.FixedHeight
  }
}
