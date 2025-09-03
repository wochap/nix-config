import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Qt5Compat.GraphicalEffects
import qs.config
import qs.services
import qs.services.SNotifications
import qs.widgets.common

PanelWindow {
  id: root

  WlrLayershell.namespace: "quickshell:notifications-panel"
  WlrLayershell.layer: WlrLayer.Overlay
  anchors {
    top: true
    left: true
    bottom: true
    right: true
  }
  exclusionMode: ExclusionMode.Ignore
  exclusiveZone: 0
  color: "transparent"
  mask: Region {
    item: rectangle
  }

  StyledRectangularShadow {
    target: rectangle
  }

  Rectangle {
    id: rectangle

    anchors {
      top: parent.top
      bottom: parent.bottom
      right: parent.right
    }
    implicitWidth: ConfigNotifications.notificationsPanelWidth
    color: Theme.options.backgroundOverlay

    ColumnLayout {
      anchors.fill: parent
      spacing: 8

      // top
      RowLayout {
        Layout.topMargin: ConfigNotifications.notificationsPanelPaddingY
        Layout.rightMargin: ConfigNotifications.notificationsPanelPaddingX
        Layout.leftMargin: ConfigNotifications.notificationsPanelPaddingX

        StyledText {
          text: "Notifications"
        }

        Button {
          text: "DND"
        }

        Button {
          text: "Clear All"
        }
      }

      // body
      ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.rightMargin: ConfigNotifications.notificationsPanelPaddingX
        Layout.leftMargin: ConfigNotifications.notificationsPanelPaddingX
        spacing: ConfigNotifications.notificationsSpacing
        model: SNotifications.list
        delegate: Notification {
          anchors.left: parent?.left
          anchors.right: parent?.right
        }
      }
    }
  }
}
