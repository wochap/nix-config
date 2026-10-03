import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.widgets.common

// Pill button: icon, text or both
Button {
  id: root

  property string materialIcon: ""
  property int materialIconSize: Styles.font.pixelSize.normal + 1
  property int textSize: Styles.font.pixelSize.small
  property int textWeight: Font.Medium
  property color fg: Theme.options.text
  property color hoverFg: fg
  property color bg: Theme.options.surface0
  property color hoverBg: Theme.options.surface1
  property color borderColor: "transparent"
  property int size: 24

  implicitHeight: root.size
  implicitWidth: root.text.length > 0 ? contentItem.implicitWidth + leftPadding + rightPadding : root.size
  verticalPadding: 0
  horizontalPadding: root.text.length > 0 ? 10 : 0
  hoverEnabled: true
  background: StyledRect {
    color: root.pressed ? Theme.options.surface2 : root.hovered ? root.hoverBg : root.bg
    radius: height / 2
    border {
      width: root.borderColor.a > 0 ? 1 : 0
      color: root.borderColor
    }
  }
  contentItem: RowLayout {
    spacing: 4

    MaterialIcon {
      visible: root.materialIcon.length > 0
      Layout.alignment: Qt.AlignCenter
      Layout.fillWidth: root.text.length === 0
      horizontalAlignment: Text.AlignHCenter
      icon: root.materialIcon
      size: root.materialIconSize
      color: root.hovered ? root.hoverFg : root.fg
      weight: Font.Normal
    }

    StyledText {
      visible: root.text.length > 0
      Layout.alignment: Qt.AlignVCenter
      text: root.text
      font.pixelSize: root.textSize
      font.weight: root.textWeight
      color: root.hovered ? root.hoverFg : root.fg
    }
  }
}
