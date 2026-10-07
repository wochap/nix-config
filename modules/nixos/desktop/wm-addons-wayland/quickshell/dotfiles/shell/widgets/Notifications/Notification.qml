import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.services.SNotifications
import qs.widgets.common
import "./Utils.js" as Util

// Notification card, used both as toast (isPopup) and as sidebar entry
Item {
  id: root

  required property SNotification notification
  required property bool isPopup
  property bool isExpanded: false
  readonly property bool isCritical: root.notification?.isCritical ?? false
  readonly property bool isLow: root.notification?.isLow ?? false
  readonly property bool hasTimeout: (root.notification?.timer ?? null) !== null && (root.notification?.time ?? 0) > 0
  readonly property bool isHovered: hoverHandler.hovered
  readonly property bool isPressed: mouseArea.pressed
  readonly property color accent: root.isCritical ? Theme.options.red : Theme.options.primary

  function timeoutNotification() {
    SNotifications.timeoutNotification(root.notification?.notificationId ?? -1);
  }

  function discardNotification() {
    SNotifications.discardNotification(root.notification?.notificationId ?? -1);
  }

  // Copies short-lived thumbnails (image-data, /tmp files) into the cache dir
  function persistThumb() {
    const notification = root.notification;
    if (!notification || notification.persistedThumb.length > 0)
      return;
    const thumb = notification.thumb;
    if (!thumb.startsWith("image://qsimage") && !thumb.startsWith("file:///tmp/"))
      return;
    const path = SNotifications.thumbCachePath(notification);
    const size = ConfigNotifications.notificationThumbSize * 2;
    thumbImage.grabToImage(result => {
      if (result.saveToFile(path)) {
        notification.persistedThumb = `file://${path}`;
        SNotifications.schedulePersist();
      }
    }, Qt.size(size, size));
  }

  implicitWidth: ConfigNotifications.notificationsPopupsWidth
  implicitHeight: card.implicitHeight

  StyledRectangularShadow {
    visible: root.isPopup
    target: card
    elevation: Styles.elevation.e2
  }

  // ClippingRectangle keeps the timeout bar inside the rounded corners
  ClippingRectangle {
    id: card

    anchors.fill: parent
    implicitHeight: content.implicitHeight + ConfigNotifications.notificationPaddingTop + ConfigNotifications.notificationPaddingBottom
    radius: Styles.radius.windowRounding
    color: root.isPressed ? Theme.options.surface0 : root.isHovered ? Theme.tint(Theme.options.base, Theme.options.surface0, 0.5) : root.isCritical ? Theme.tint(Theme.options.base, Theme.options.red, 0.04) : Theme.options.base
    border {
      width: 1
      color: root.isCritical ? Theme.addAlpha(Theme.options.red, 0.6) : (root.isHovered || root.isPressed) ? Theme.options.surface1 : Theme.options.surface0
    }

    Behavior on color {
      animation: Styles.animations.colorAnimation.createObject(this)
    }

    HoverHandler {
      id: hoverHandler
    }

    MouseArea {
      id: mouseArea

      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      Accessible.role: Accessible.Button
      Accessible.name: [root.notification?.appName, root.notification?.summary].filter(Boolean).join(": ")
      Accessible.description: root.isExpanded ? "Expanded" : "Collapsed"
      Accessible.onPressAction: root.isExpanded = !root.isExpanded
      onClicked: event => {
        if (!root.notification)
          return;
        switch (event.button) {
        case Qt.LeftButton:
          root.isExpanded = !root.isExpanded;
          break;
        case Qt.RightButton:
          if (root.isPopup)
            root.timeoutNotification();
          else
            root.discardNotification();
          break;
        }
        event.accepted = true;
      }
    }

    ColumnLayout {
      id: content

      anchors {
        top: parent.top
        left: parent.left
        right: parent.right
        topMargin: ConfigNotifications.notificationPaddingTop
        leftMargin: ConfigNotifications.notificationPaddingLeft
        rightMargin: ConfigNotifications.notificationPaddingRight
      }
      spacing: ConfigNotifications.notificationSpacing

      // header: icon · app · time · CRITICAL ... expand close
      RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: ConfigNotifications.notificationHeaderHeight
        Layout.maximumHeight: ConfigNotifications.notificationHeaderHeight
        spacing: 6

        SystemIcon {
          Layout.alignment: Qt.AlignVCenter
          icon: root.notification?.headerIcon ?? ""
          size: ConfigNotifications.notificationHeaderIconSize
          iconFallback: "notification-inactive"
        }

        StyledText {
          Layout.maximumWidth: 160
          text: root.notification?.appName ?? ""
          color: Theme.options.subtext0
          font.pixelSize: Styles.font.pixelSize.smaller
          font.letterSpacing: 0.2
          elide: Text.ElideRight
        }

        StyledText {
          text: `· ${Util.formatTimeAgo(root.notification?.time ?? 0)}`
          color: Theme.options.overlay0
          font.pixelSize: Styles.font.pixelSize.smaller
        }

        Rectangle {
          visible: root.isCritical
          implicitWidth: criticalText.implicitWidth + 12
          implicitHeight: 16
          radius: 8
          color: Theme.addAlpha(Theme.options.red, 0.14)

          StyledText {
            id: criticalText

            anchors.centerIn: parent
            text: "CRITICAL"
            color: Theme.options.red
            font.pixelSize: Styles.font.pixelSize.smaller
            font.weight: Font.Bold
            font.letterSpacing: 0.6
          }
        }

        Item {
          Layout.fillWidth: true
        }

        // 22px buttons overflow the 18px header row (as in the design),
        // so they don't push the row height and unbalance the padding
        Item {
          visible: bodyText.truncated || metaText.truncated || root.isExpanded
          implicitWidth: expandButton.implicitWidth
          implicitHeight: ConfigNotifications.notificationHeaderHeight

          NotificationButtonSm {
            id: expandButton

            anchors.centerIn: parent
            materialIcon: root.isExpanded ? "unfold_less" : "unfold_more"
            Accessible.name: root.isExpanded ? "Collapse" : "Expand"
            onClicked: root.isExpanded = !root.isExpanded
          }
        }

        Item {
          implicitWidth: closeButton.implicitWidth
          implicitHeight: ConfigNotifications.notificationHeaderHeight

          NotificationButtonSm {
            id: closeButton

            anchors.centerIn: parent
            materialIcon: "close"
            Accessible.name: "Dismiss"
            onClicked: root.discardNotification()
          }
        }
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: 10

        ColumnLayout {
          Layout.fillWidth: true
          Layout.alignment: Qt.AlignTop
          spacing: 2

          StyledText {
            Layout.fillWidth: true
            visible: text.length > 0
            text: root.notification?.summary ?? ""
            color: root.isLow ? Theme.options.subtext1 : Theme.options.text
            font.pixelSize: Styles.font.pixelSize.normal
            font.weight: Font.Medium
            lineHeight: 18
            lineHeightMode: Text.FixedHeight
            wrapMode: Text.Wrap
            textFormat: Text.PlainText
          }

          StyledText {
            id: metaText

            Layout.fillWidth: true
            visible: text.length > 0
            text: root.notification?.meta ?? ""
            color: Theme.options.overlay1
            font.pixelSize: Styles.font.pixelSize.smaller
            lineHeight: 14
            lineHeightMode: Text.FixedHeight
            elide: root.isExpanded ? Text.ElideNone : Text.ElideRight
            wrapMode: root.isExpanded ? Text.Wrap : Text.NoWrap
            textFormat: Text.PlainText
          }

          StyledText {
            id: bodyText

            Layout.fillWidth: true
            visible: text.length > 0
            text: root.notification?.body ?? ""
            color: root.isLow ? Theme.options.subtext0 : Theme.options.subtext1
            font.pixelSize: Styles.font.pixelSize.small
            lineHeight: 16
            lineHeightMode: Text.FixedHeight
            wrapMode: Text.Wrap
            maximumLineCount: root.isExpanded ? 100 : 2
            elide: Text.ElideRight
            textFormat: Text.StyledText
            onLinkActivated: link => Qt.openUrlExternally(link)
          }

          StyledText {
            Layout.fillWidth: true
            Layout.topMargin: 2
            visible: text.length > 0
            text: root.notification?.foot ?? ""
            color: Theme.options.overlay0
            font.pixelSize: Styles.font.pixelSize.smaller
            lineHeight: 14
            lineHeightMode: Text.FixedHeight
            elide: Text.ElideRight
            textFormat: Text.PlainText
          }
        }

        ClippingRectangle {
          id: thumb

          visible: (root.notification?.thumb ?? "") !== "" && thumbImage.status !== Image.Error
          Layout.alignment: Qt.AlignTop
          implicitWidth: ConfigNotifications.notificationThumbSize
          implicitHeight: ConfigNotifications.notificationThumbSize
          radius: Styles.radius.small
          color: Theme.options.mantle

          Image {
            id: thumbImage

            anchors.fill: parent
            source: root.notification?.thumb ?? ""
            sourceSize: Qt.size(ConfigNotifications.notificationThumbSize * 2, ConfigNotifications.notificationThumbSize * 2)
            fillMode: Image.PreserveAspectCrop
            smooth: true
            asynchronous: true
            onStatusChanged: {
              if (status === Image.Ready)
                root.persistThumb();
            }
          }

          Rectangle {
            anchors.fill: parent
            color: "transparent"
            radius: thumb.radius
            border {
              width: 1
              color: Theme.options.surface0
            }
          }
        }
      }

      Flow {
        Layout.fillWidth: true
        Layout.topMargin: 2
        visible: (root.notification?.actions?.length ?? 0) > 0
        spacing: 6

        Repeater {
          model: root.notification?.actions ?? []
          delegate: NotificationButtonMd {
            required property var modelData
            required property int index

            isPrimary: index === 0
            accent: root.accent
            text: modelData.text.trim().length > 0 ? modelData.text : "Default"
            onClicked: SNotifications.attemptInvokeAction(root.notification?.notificationId ?? -1, modelData.identifier)
          }
        }
      }
    }

    // timeout bar
    Rectangle {
      visible: root.isPopup && root.hasTimeout && !root.isCritical
      anchors {
        left: parent.left
        bottom: parent.bottom
      }
      width: parent.width * (root.notification?.timer?.progress ?? 1)
      height: ConfigNotifications.notificationTimeoutBarHeight
      topRightRadius: height
      bottomRightRadius: height
      color: root.isLow ? Theme.options.overlay1 : Theme.options.primary
    }
  }
}
