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
    leftMargin: ConfigNotifications.notificationPadding
    rightMargin: ConfigNotifications.notificationPadding
    topMargin: ConfigNotifications.notificationPadding * 2
    bottomMargin: isPopup ? 0 : ConfigNotifications.notificationPadding * 2
    border {
      width: 1
      color: Theme.options.borderSecondary
    }

    child: ColumnLayout {
      id: notificationContent

      spacing: ConfigNotifications.notificationPadding

      RowLayout {
        id: rowLayout

        spacing: ConfigNotifications.notificationPadding

        SystemIcon {
          Layout.alignment: right.implicitHeight > 80 ? Qt.AlignTop : Qt.AlignVCenter
          icon: root.notification.appIcon
          size: 36
        }

        ColumnLayout {
          id: right

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

            NotificationButtonSm {
              materialIcon: "close"
              onClicked: {
                SNotifications.discardNotification(root.notification.notificationId);
              }
            }

            NotificationButtonSm {
              visible: root.isPopup
              materialIcon: "chevron_right"
              onClicked: {
                SNotifications.timeoutNotification(root.notification.notificationId);
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

          ColumnLayout {
            spacing: 3

            StyledText {
              visible: root.notification.body.length > 0
              Layout.fillWidth: true
              text: root.notification.body
              color: Theme.options.subtext0
              font.pixelSize: Styles.font.pixelSize.small
              elide: Text.ElideMiddle
              wrapMode: root.isExpanded ? Text.WordWrap : Text.NoWrap
              maximumLineCount: root.isExpanded ? 0 : 1
              clip: true
            }

            RowLayout {
              visible: root.notification.actions.length > 0
              Layout.topMargin: ConfigNotifications.notificationPadding / 2
              spacing: ConfigNotifications.notificationPadding

              Repeater {
                model: root.notification.actions
                delegate: NotificationButtonMd {
                  text: modelData.text.trim().length > 0 ? modelData.text : "Default"
                  onClicked: {
                    SNotifications.attemptInvokeAction(root.notification.notificationId, modelData.identifier);
                  }
                }
              }
            }
          }
        }
      }

      Rectangle {
        Layout.topMargin: wrapperRectangle.topMargin - notificationContent.spacing
        visible: root.isPopup
        implicitWidth: parent.width * (root.notification?.timer?.progress ?? 0.5)
        implicitHeight: 1
        color: Theme.options.primary
      }
    }
  }
}
