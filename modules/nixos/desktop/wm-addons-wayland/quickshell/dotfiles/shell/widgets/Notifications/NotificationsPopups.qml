import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Qt5Compat.GraphicalEffects
import qs.config
import qs.services
import qs.services.SNotifications
import qs.widgets.common

PanelWindow {
  id: root

  property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null

  WlrLayershell.namespace: "quickshell:notifications-popups"
  WlrLayershell.layer: WlrLayer.Overlay
  anchors {
    top: true
    bottom: true
    right: true
    left: true
  }
  screen: focusedScreen
  exclusionMode: ExclusionMode.Normal
  exclusiveZone: 0
  color: "transparent"
  mask: Region {
    item: listview.contentItem
  }

  StyledListView {
    id: listview

    anchors {
      top: parent.top
      bottom: parent.bottom
      right: parent.right
      topMargin: 8
      rightMargin: anchors.topMargin
    }
    bottomMargin: anchors.topMargin
    implicitWidth: ConfigNotifications.notificationsPopupsWidth
    // TODO: find why spacing between items is being blur out
    spacing: ConfigNotifications.notificationsSpacing
    clip: false
    // PERF: do granular updates with ScriptModel
    model: ScriptModel {
      values: SNotifications.popupList
    }
    delegate: NotificationItem {
      isPopup: true
      anchors.left: parent?.left
      anchors.right: parent?.right
    }

    HoverHandler {
      onHoveredChanged: {
        SNotifications.arePopupsHovered = hovered;
      }
    }
  }
}
