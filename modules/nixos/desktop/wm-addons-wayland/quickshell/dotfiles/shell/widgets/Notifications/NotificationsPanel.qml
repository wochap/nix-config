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
  exclusionMode: ExclusionMode.Normal
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
      topMargin: 8
      bottomMargin: anchors.topMargin
      rightMargin: anchors.topMargin
    }
    radius: Styles.radius.windowRounding
    implicitWidth: ConfigNotifications.notificationsPanelWidth
    color: Theme.options.backgroundOverlay
    border {
      width: 1
      color: Theme.options.borderSecondary
    }

    ColumnLayout {
      anchors.fill: parent
      spacing: rectangle.anchors.topMargin

      // header
      RowLayout {
        Layout.topMargin: ConfigNotifications.notificationsPanelPaddingY
        Layout.rightMargin: ConfigNotifications.notificationsPanelPaddingX
        Layout.leftMargin: ConfigNotifications.notificationsPanelPaddingX
        z: 1

        StyledText {
          Layout.fillWidth: true
          text: "Notifications"
          font.pixelSize: Styles.font.pixelSize.normal
        }

        NotificationButtonMd {
          materialIcon: SNotifications.isSilent ? "do_not_disturb_on" : "do_not_disturb_off"
          onClicked: {
            SNotifications.toggleIsSilent();
          }
        }

        NotificationButtonMd {
          materialIcon: "clear_all"
          onClicked: {
            SNotifications.discardAllNotifications();
          }
        }
      }

      // body
      StyledListView {
        visible: SNotifications.list.length > 0
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.bottomMargin: rectangle.border.width
        rightMargin: ConfigNotifications.notificationsPanelPaddingX
        leftMargin: ConfigNotifications.notificationsPanelPaddingX
        bottomMargin: ConfigNotifications.notificationsPanelPaddingX
        spacing: ConfigNotifications.notificationsSpacing
        clip: true
        // PERF: do granular updates with ScriptModel
        model: ScriptModel {
          values: SNotifications.list
        }
        delegate: NotificationItem {
          isPopup: false
          anchors.left: parent?.left
          anchors.right: parent?.right
        }
        ScrollIndicator.vertical: ScrollIndicator {}
      }

      StyledText {
        visible: SNotifications.list.length === 0
        Layout.fillHeight: true
        Layout.alignment: Qt.AlignHCenter
        text: "No notifications"
        color: Theme.options.textDimmed
      }
    }
  }
}
