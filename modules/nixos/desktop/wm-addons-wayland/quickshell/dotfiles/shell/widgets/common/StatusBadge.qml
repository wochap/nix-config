import QtQuick
import QtQuick.Layouts
import qs.config
import qs.widgets.common

// Icon + optional counter/label used by bar status modules. Lays out as a row
// (horizontal bar) or a centered column (`vertical`, vertical bar).
GridLayout {
  id: root

  property bool vertical: false
  property real itemSpacing: root.vertical ? 1 : 4
  // Material icon; takes precedence over `woosIcon`
  property string icon: ""
  property string woosIcon: ""
  property color iconColor: Theme.options.text
  property int iconSize: 19
  property string text: ""
  property bool textVisible: root.text.length > 0
  property int fontSize: 10

  readonly property int itemAlignment: root.vertical ? Qt.AlignHCenter : Qt.AlignVCenter

  flow: root.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
  rowSpacing: root.itemSpacing
  columnSpacing: root.itemSpacing

  MaterialIcon {
    Layout.alignment: root.itemAlignment
    visible: root.icon.length > 0
    icon: root.icon
    size: root.iconSize
    weight: Font.Normal
    color: root.iconColor
  }

  WoosIcon {
    Layout.alignment: root.itemAlignment
    visible: root.woosIcon.length > 0 && root.icon.length === 0
    icon: root.woosIcon
    size: root.iconSize
    color: root.iconColor
  }

  StyledText {
    Layout.alignment: root.itemAlignment
    visible: root.textVisible
    text: root.text
    font.pixelSize: root.fontSize
    font.weight: 600
    color: Theme.options.subtext1
  }
}
