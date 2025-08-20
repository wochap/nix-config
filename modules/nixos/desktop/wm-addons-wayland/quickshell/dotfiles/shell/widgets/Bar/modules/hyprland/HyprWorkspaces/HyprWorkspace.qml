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
  required property var workspace
  required property HyprlandMonitor monitor
  required property bool occupied
  property int workspaceId: index + 1
  property bool focused: monitor?.activeWorkspace?.id === workspaceId

  Layout.fillHeight: true

  onPressed: Hyprland.dispatch(`workspace ${workspaceId}`)
  verticalPadding: 0
  horizontalPadding: styledText.font.pixelSize * 0.4
  background: Rectangle {
    color: focused ? Theme.options.surface0 : "transparent"
    radius: 4
  }
  contentItem: StyledText {
    id: styledText

    color: focused && occupied ? Theme.options.primary : (occupied ? Theme.options.text : Theme.options.textDimmed)
    text: workspaceId
    anchors.centerIn: parent
    verticalAlignment: Text.AlignVCenter
    // font.weight: Font.Normal
  }
}
