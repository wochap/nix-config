import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.config
import qs.services
import qs.services.SNotifications
import qs.widgets.common
import "./Utils.js" as Util

Item {
  id: root

  required property SNotification notification
  required property bool isPopup
  property bool isExpanded: true

  implicitWidth: wrapperRectangle.implicitWidth
  implicitHeight: wrapperRectangle.implicitHeight

  StyledRectangularShadow {
    visible: isPopup
    target: wrapperRectangle
  }

  WrapperRectangle {
    id: wrapperRectangle

    anchors.fill: parent
    color: Theme.addAlpha(root.isPopup ? Theme.options.backgroundOverlay : Theme.options.background, root.isPopup && Global.isBlurEnabled ? 0.65 : 1)
    radius: 8
    margin: ConfigNotifications.notificationPadding
    border {
      width: 1
      color: Theme.options.borderSecondary
    }

    child: ColumnLayout {
      spacing: ConfigNotifications.notificationPadding

      RowLayout {
        id: rowLayout

        spacing: ConfigNotifications.notificationPadding

        SystemIcon {
          icon: root.notification.appIcon
          size: 32
        }

        ColumnLayout {
          spacing: 0

          RowLayout {
            spacing: ConfigNotifications.notificationPadding

            StyledText {
              Layout.fillWidth: true
              text: root.notification?.appName ?? ""
              color: Theme.options.subtext1
              font.pixelSize: Styles.font.pixelSize.smaller
            }

            StyledText {
              text: Util.formatTimeAgo(root.notification.time)
              color: Theme.options.overlay0
              font.pixelSize: Styles.font.pixelSize.smaller
            }

            NotificationButton {
              materialIcon: "close"
              onClicked: {
                // TODO: when in panel it takes much time to delete
                print(root.notification.notificationId)
                SNotifications.discardNotification(root.notification.notificationId);
              }
            }
          }

          StyledText {
            Layout.fillWidth: true
            text: root.notification.summary
            font.pixelSize: Styles.font.pixelSize.small
            elide: Text.ElideMiddle
            wrapMode: root.isExpanded ? Text.WordWrap : Text.NoWrap
          }

          StyledText {
            visible: root.notification.body.length > 0
            Layout.fillWidth: true
            text: root.notification.body
            color: Theme.options.subtext0
            font.pixelSize: Styles.font.pixelSize.small
            wrapMode: Text.WordWrap
          }
        }
      }

      Rectangle {
        visible: root.isPopup
        implicitWidth: parent.width * (root.notification?.timer?.progress ?? 0.5)
        implicitHeight: 1
        color: Theme.options.primary
      }
    }
  }
}
