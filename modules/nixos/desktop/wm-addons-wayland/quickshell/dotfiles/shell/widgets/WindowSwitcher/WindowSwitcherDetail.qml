import QtQuick
import QtQuick.Layouts
import qs.config
import qs.widgets.common

// Detail row under the tiles: full (wrapping) title plus window metadata.
Rectangle {
  id: root

  property var entry: null
  property string meta: ""
  // Shown instead of the window details when there is no entry.
  property string placeholder: ""

  implicitHeight: content.implicitHeight + 16
  radius: Styles.radius.medium
  color: Theme.options.backgroundOverlay
  border {
    width: 1
    color: Theme.options.borderSecondary
  }

  RowLayout {
    id: content

    anchors {
      fill: parent
      topMargin: 8
      bottomMargin: 8
      leftMargin: 10
      rightMargin: 10
    }
    spacing: 8

    SystemIcon {
      Layout.alignment: Qt.AlignTop
      visible: root.entry !== null
      icon: root.entry?.icon ?? ""
      size: 18
    }

    StyledText {
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignTop
      lineHeight: 18
      lineHeightMode: Text.FixedHeight
      wrapMode: root.entry ? Text.WrapAnywhere : Text.WordWrap
      font.pixelSize: Styles.font.pixelSize.small
      color: root.entry ? Theme.options.text : Theme.options.overlay1
      text: root.entry ? (root.entry.title ?? "") : root.placeholder
    }

    StyledText {
      Layout.alignment: Qt.AlignTop
      Layout.maximumWidth: content.width / 2
      elide: Text.ElideLeft
      lineHeight: 18
      lineHeightMode: Text.FixedHeight
      font.pixelSize: Styles.font.pixelSize.smaller
      color: Theme.options.overlay1
      text: root.meta
    }
  }
}
