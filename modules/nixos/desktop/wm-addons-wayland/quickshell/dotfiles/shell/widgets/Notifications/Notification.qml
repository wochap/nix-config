import Quickshell
import Quickshell.Widgets
import QtQuick
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
  property bool hasTimeout: (root.notification?.timer ?? null) !== null && root.notification.time > 0

  implicitWidth: wrapperRectangle.implicitWidth
  implicitHeight: wrapperRectangle.implicitHeight

  Component.onCompleted: {
    root.isExpanded = !isPopup;
  }

  StyledRectangularShadow {
    visible: isPopup
    target: wrapperRectangle
  }

  WrapperRectangle {
    id: wrapperRectangle

    anchors.fill: parent
    color: Theme.addAlpha(root.isPopup ? Theme.options.backgroundOverlay : Theme.options.background, root.isPopup && Global.isBlurEnabled ? 0.65 : 1)
    radius: Styles.radius.windowRounding
    leftMargin: ConfigNotifications.notificationPadding
    rightMargin: ConfigNotifications.notificationPadding
    topMargin: ConfigNotifications.notificationPadding * 2
    bottomMargin: isPopup && hasTimeout ? 0 : ConfigNotifications.notificationPadding * 2
    border {
      width: 1
      color: Theme.options.borderSecondary
    }

    child: Item {
      implicitWidth: notificationContent.implicitWidth
      implicitHeight: notificationContent.implicitHeight

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: event => {
          switch (event.button) {
          case Qt.LeftButton:
            if (root.isPopup) {
              root.isExpanded = !root.isExpanded;
            }
            break;
          case Qt.RightButton:
            if (root.isPopup) {
              SNotifications.timeoutNotification(root.notification.notificationId);
            } else {
              SNotifications.discardNotification(root.notification.notificationId);
            }
            break;
          }
          event.accepted = true;
        }
      }

      ColumnLayout {
        id: notificationContent

        anchors.fill: parent
        spacing: ConfigNotifications.notificationPadding

        RowLayout {
          id: rowLayout

          spacing: ConfigNotifications.notificationPadding

          SystemIcon {
            Layout.alignment: right.implicitHeight > 80 ? Qt.AlignTop : Qt.AlignVCenter
            icon: root.notification.appIcon
            size: 36
            iconFallback: "org.xfce.notification"
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
                visible: root.isPopup
                materialIcon: root.isExpanded ? "unfold_less" : "unfold_more"
                onClicked: {
                  root.isExpanded = !root.isExpanded;
                }
              }

              NotificationButtonSm {
                visible: root.isPopup
                materialIcon: "chevron_right"
                onClicked: {
                  SNotifications.timeoutNotification(root.notification.notificationId);
                }
              }

              NotificationButtonSm {
                materialIcon: "close"
                onClicked: {
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
                textFormat: Text.RichText
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
          Layout.topMargin: wrapperRectangle.topMargin - notificationContent.spacing + 1
          visible: root.isPopup && root.hasTimeout
          implicitWidth: parent.width * (root.notification?.timer?.progress ?? 1)
          implicitHeight: 1
          color: Theme.options.primary
        }
      }
    }
  }

  RetainableLock {
    object: root.notification.notification
    locked: true
  }
}
