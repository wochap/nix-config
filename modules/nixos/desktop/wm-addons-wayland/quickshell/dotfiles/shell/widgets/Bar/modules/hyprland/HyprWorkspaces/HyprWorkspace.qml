pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Hyprland

import qs.config
import qs.widgets.common

Button {
  id: root

  required property int index

  Layout.fillHeight: true

  onPressed: Hyprland.dispatch(`workspace ${index + 1}`)
  verticalPadding: 0
  horizontalPadding: styledText.font.pixelSize * 0.4
  background: Rectangle {
    color: Theme.options.surface0
    radius: 4
  }
  contentItem: StyledText {
    id: styledText

    text: root.index + 1
    anchors.centerIn: parent
    verticalAlignment: Text.AlignVCenter
    // font.weight: Font.Normal
  }
}
