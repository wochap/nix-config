pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.widgets.common
import qs.widgets.AuthPrompt
import qs.widgets.Lock

// countdown confirm for restart / shut down / log out, see design/project/ConfirmDialog.dc.html
// The countdown never pauses, Esc is always one key away.
FocusScope {
  id: root

  // restart | shutdown | logout
  required property string action
  // where the request came from, shown under the title
  property string origin: "logind · from lock screen"
  readonly property var spec: ({
      shutdown: {
        icon: "power_settings_new",
        tint: Theme.options.red,
        title: "Shut down?",
        verb: "shut down",
        primary: "Shut down now"
      },
      restart: {
        icon: "restart_alt",
        tint: Theme.options.red,
        title: "Restart?",
        verb: "restart",
        primary: "Restart now"
      },
      logout: {
        icon: "logout",
        tint: ConfigLock.ink,
        title: "Log out?",
        verb: "log you out",
        primary: "Log out now"
      }
    })[root.action] ?? {}
  property int remaining: ConfigLock.confirmSeconds
  readonly property bool isLate: root.remaining <= 3

  signal confirmed
  signal canceled

  implicitWidth: ConfigLock.confirmWidth
  implicitHeight: card.height
  focus: true

  Component.onCompleted: confirmButton.forceActiveFocus()

  Keys.onPressed: event => {
    if (event.key === Qt.Key_Escape) {
      root.canceled();
      event.accepted = true;
    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
      if (cancelButton.activeFocus) {
        root.canceled();
      } else {
        root.confirmed();
      }
      event.accepted = true;
    } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Right || event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
      if (cancelButton.activeFocus) {
        confirmButton.forceActiveFocus();
      } else {
        cancelButton.forceActiveFocus();
      }
      event.accepted = true;
    }
  }

  Timer {
    running: root.remaining > 0
    interval: 1000
    repeat: true
    onTriggered: {
      root.remaining = Math.max(0, root.remaining - 1);
      if (root.remaining === 0) {
        root.confirmed();
      }
    }
  }

  StyledRectangularShadow {
    target: card
    elevation: Styles.elevation.e2
  }

  StyledRect {
    id: card

    width: root.width
    height: content.implicitHeight
    radius: ConfigLock.radius
    color: Theme.options.base

    MouseArea {
      anchors.fill: parent
    }

    ColumnLayout {
      id: content

      anchors {
        left: parent.left
        right: parent.right
      }
      spacing: 0

      RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 16
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        spacing: 12

        StyledRect {
          Layout.preferredWidth: 32
          Layout.preferredHeight: 32
          radius: ConfigLock.radius
          color: Theme.addAlpha(String(root.spec.tint), ConfigLock.openTint)

          MaterialIcon {
            anchors.centerIn: parent
            icon: root.spec.icon ?? ""
            size: 20
            fill: 1
            weight: Font.Normal
            color: root.spec.tint ?? Theme.options.text
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 0

          StyledText {
            text: root.spec.title ?? ""
            font.pixelSize: Styles.font.pixelSize.large
            font.weight: Font.Medium
          }

          RowLayout {
            spacing: 4

            MaterialIcon {
              icon: "lock"
              size: 14
              fill: 1
              weight: Font.Normal
              color: ConfigLock.subtext
            }

            StyledText {
              text: root.origin
              color: ConfigLock.subtext
              font.pixelSize: Styles.font.pixelSize.small
            }
          }
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: 12
        Layout.bottomMargin: 16
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        spacing: 4

        StyledText {
          Layout.fillWidth: true
          text: root.action === "logout" ? `This will ${root.spec.verb} in ${root.remaining}s.` : `The computer will ${root.spec.verb} in ${root.remaining}s.`
          wrapMode: Text.Wrap
          lineHeight: 20
          lineHeightMode: Text.FixedHeight
        }

        StyledText {
          Layout.fillWidth: true
          text: "Unsaved work in open apps will be lost."
          color: ConfigLock.subtext
          wrapMode: Text.Wrap
          font.pixelSize: Styles.font.pixelSize.small
        }
      }

      RowLayout {
        Layout.alignment: Qt.AlignRight
        Layout.rightMargin: 16
        Layout.bottomMargin: 16
        spacing: 8

        AuthButton {
          id: cancelButton

          label: "Cancel"
          keycap: "Esc"
          ink: ConfigLock.ink
          labelSize: Styles.font.pixelSize.small
          onClicked: root.canceled()
        }

        AuthButton {
          id: confirmButton

          label: root.spec.primary ?? ""
          keycap: "↵"
          kind: "tinted"
          tint: root.spec.tint ?? Theme.options.red
          ink: ConfigLock.ink
          labelSize: Styles.font.pixelSize.small
          onClicked: root.confirmed()
        }
      }

      // footer, the countdown bar drains along its top edge
      StyledRect {
        Layout.fillWidth: true
        Layout.preferredHeight: footerRow.implicitHeight + 16
        color: Theme.options.mantle
        bottomLeftRadius: ConfigLock.radius
        bottomRightRadius: ConfigLock.radius

        StyledRect {
          anchors {
            top: parent.top
            left: parent.left
            right: parent.right
          }
          height: 1
          color: Theme.options.surface0
        }

        StyledRect {
          anchors {
            top: parent.top
            left: parent.left
          }
          height: 2
          width: parent.width * root.remaining / ConfigLock.confirmSeconds
          color: root.isLate ? Theme.options.red : ConfigLock.ink

          Behavior on width {
            NumberAnimation {
              duration: 1000
            }
          }
        }

        RowLayout {
          id: footerRow

          anchors {
            left: parent.left
            leftMargin: 16
            verticalCenter: parent.verticalCenter
          }
          spacing: 6

          MaterialIcon {
            icon: "timer"
            size: 16
            weight: Font.Normal
            color: ConfigLock.subtext
          }

          StyledText {
            text: "Confirms automatically in"
            color: ConfigLock.subtext
            font.pixelSize: Styles.font.pixelSize.small
          }

          StyledText {
            text: `0:${String(root.remaining).padStart(2, "0")}`
            color: root.isLate ? Theme.options.red : Theme.options.text
            font.pixelSize: Styles.font.pixelSize.small
            font.features: {
              "tnum": 1
            }
          }
        }
      }
    }

    // edge on top of the content so the footer doesn't cover it
    StyledRect {
      anchors.fill: parent
      radius: ConfigLock.radius
      border.width: 1
      border.color: ConfigLock.ink
    }
  }
}
