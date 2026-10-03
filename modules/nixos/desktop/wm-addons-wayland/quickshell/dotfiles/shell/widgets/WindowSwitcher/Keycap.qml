import QtQuick
import qs.config
import qs.widgets.common

// Keycap: h20 · min-w20 · px5 · r4 with a 2px bottom edge. `accent` renders
// the submap-key variant used for harpoon slots over window previews.
Item {
  id: root

  required property string text
  property bool accent: true

  readonly property color edgeColor: root.accent ? Theme.addAlpha(Theme.options.primary, 0.55) : Theme.options.surface1

  implicitHeight: 20
  implicitWidth: Math.max(20, label.implicitWidth + 10)

  // Bottom edge peeking 2px below the face.
  Rectangle {
    anchors.fill: parent
    radius: Styles.radius.small
    color: root.edgeColor
  }

  Rectangle {
    anchors {
      fill: parent
      bottomMargin: 2
    }
    radius: Styles.radius.small
    color: root.accent ? Theme.addAlpha(Theme.options.crust, 0.85) : Theme.options.surface0
    border {
      width: 1
      color: root.edgeColor
    }

    StyledText {
      id: label

      anchors.centerIn: parent
      text: root.text
      font.pixelSize: Styles.font.pixelSize.small
      font.weight: root.accent ? Font.Bold : Font.Normal
      color: root.accent ? Theme.options.primary : Theme.options.text
    }
  }
}
