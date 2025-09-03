import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Qt5Compat.GraphicalEffects
import qs.config
import qs.services
import qs.services.SNotifications
import qs.widgets.common

PanelWindow {
  id: root

  WlrLayershell.namespace: "quickshell:notifications-popups"
  WlrLayershell.layer: WlrLayer.Overlay
  anchors {
    top: true
    bottom: true
    right: true
    left: true
  }
  exclusionMode: ExclusionMode.Normal
  exclusiveZone: 0
  color: "transparent"
  mask: Region {
    item: listview.contentItem
  }

  ListView {
    id: listview

    anchors {
      top: parent.top
      bottom: parent.bottom
      right: parent.right
      topMargin: 8
      rightMargin: anchors.topMargin
    }
    implicitWidth: ConfigNotifications.notificationsPopupsWidth
    spacing: ConfigNotifications.notificationsSpacing
    clip: true
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
