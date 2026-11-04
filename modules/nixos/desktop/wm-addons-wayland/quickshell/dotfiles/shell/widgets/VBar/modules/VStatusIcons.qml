pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.config
import qs.services
import qs.services.SNotifications
import qs.widgets.common
import qs.widgets.VBar.config

ColumnLayout {
  id: root

  property bool isFocused: true
  spacing: ConfigVBar.modulesSpacing

  // Capslock
  Loader {
    id: capslock

    Layout.alignment: Qt.AlignHCenter
    property bool isVisible: SCapslock.isLock
    active: isVisible
    visible: isVisible
    sourceComponent: Component {
      Rectangle {
        implicitWidth: 36
        implicitHeight: 22
        radius: 11
        color: Theme.addAlpha(Theme.options.peach, 0.18)

        MaterialIcon {
          anchors.centerIn: parent
          icon: "keyboard_capslock"
          size: 17
          weight: Font.Normal
          color: Theme.options.peach
        }
      }
    }
  }

  // Idle Inhibit
  Loader {
    id: idleInhibit

    Layout.alignment: Qt.AlignHCenter
    property bool isIdleInhibit: false
    property bool isVisible: isIdleInhibit
    active: isVisible
    visible: isVisible
    sourceComponent: Component {
      MaterialIcon {
        icon: "coffee"
        size: ConfigVBar.statusIconSize
        weight: Font.Normal
        fill: 1
        color: Theme.options.peach
      }
    }

    Process {
      command: ["shell-idle-inhibit", "--listen"]
      running: true
      stdout: SplitParser {
        onRead: data => {
          const isIdleInhibit = JSON.parse(data);
          idleInhibit.isIdleInhibit = isIdleInhibit;
        }
      }
    }
  }

  // Agents
  Loader {
    id: agents

    Layout.alignment: Qt.AlignHCenter
    property int runningCount: SAgents.runningCount
    property int blockedCount: SAgents.blockedCount
    property bool isVisible: runningCount > 0 || blockedCount > 0
    active: isVisible
    visible: isVisible
    sourceComponent: Component {
      ColumnLayout {
        spacing: 1

        MaterialIcon {
          Layout.alignment: Qt.AlignHCenter
          icon: agents.blockedCount > 0 ? "pending_actions" : "smart_toy"
          size: ConfigVBar.statusIconSize
          weight: Font.Normal
          color: agents.blockedCount > 0 ? Theme.options.yellow : Theme.options.mauve
        }

        StyledText {
          Layout.alignment: Qt.AlignHCenter
          readonly property int total: agents.runningCount + agents.blockedCount
          visible: total > 1
          text: total.toString()
          font.pixelSize: ConfigVBar.statusFontSize
          font.weight: 600
          color: Theme.options.subtext1
        }
      }
    }
  }

  // Tt (Timewarrior / Time tracking)
  Loader {
    id: tt

    Layout.alignment: Qt.AlignHCenter
    property bool isVisible: STt.count > 0
    active: isVisible
    visible: isVisible
    sourceComponent: Component {
      ColumnLayout {
        spacing: 4

        Repeater {
          model: STt.running

          Item {
            id: ttItem

            required property var modelData
            implicitWidth: ttCol.implicitWidth
            implicitHeight: ttCol.implicitHeight

            ColumnLayout {
              id: ttCol

              anchors.centerIn: parent
              spacing: 1

              MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                icon: "timer"
                size: ConfigVBar.statusIconSize
                weight: Font.Normal
                color: Theme.options.green
              }

              StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: STt.elapsed(ttItem.modelData)
                font.pixelSize: ConfigVBar.statusFontSize
                font.weight: 600
                color: Theme.options.subtext1
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              acceptedButtons: Qt.LeftButton | Qt.MiddleButton
              onClicked: event => {
                if (event.button === Qt.MiddleButton)
                  STt.stopAll();
                else
                  STt.stop(ttItem.modelData.id);
              }
            }
          }
        }
      }
    }
  }

  // Silent / DND Notification state
  Loader {
    id: notifications

    Layout.alignment: Qt.AlignHCenter
    property bool isVisible: SNotifications.isSilent
    active: isVisible
    visible: isVisible
    sourceComponent: Component {
      WoosIcon {
        icon: ""
        size: ConfigVBar.statusIconSize
        color: Theme.options.red
      }
    }
  }

  // Unread Mail
  Loader {
    id: mail

    Layout.alignment: Qt.AlignHCenter
    property int unread: SMail.unread
    property bool isVisible: unread > 0
    active: isVisible
    visible: isVisible
    sourceComponent: Component {
      ColumnLayout {
        spacing: 1

        MaterialIcon {
          Layout.alignment: Qt.AlignHCenter
          icon: "mail"
          size: ConfigVBar.statusIconSize
          weight: Font.Normal
          color: Theme.options.blue
        }

        StyledText {
          Layout.alignment: Qt.AlignHCenter
          text: mail.unread.toString()
          font.pixelSize: ConfigVBar.statusFontSize
          font.weight: 600
          color: Theme.options.subtext1
        }
      }
    }
  }

  // Offlinemsmtp outbox
  Loader {
    id: offlinemsmtp

    Layout.alignment: Qt.AlignHCenter
    property bool isActive: SOfflinemsmtp.isActive
    active: isActive
    visible: isActive
    sourceComponent: Component {
      MaterialIcon {
        icon: "outbox"
        size: ConfigVBar.statusIconSize
        weight: Font.Normal
        color: Theme.options.yellow
      }
    }
  }

  // Screen recorder
  Loader {
    id: recorder

    Layout.alignment: Qt.AlignHCenter
    property bool isRecording: SRecorder.isRecording
    active: isRecording
    visible: isRecording
    sourceComponent: Component {
      Rectangle {
        implicitWidth: 36
        implicitHeight: 22
        radius: 11
        color: Theme.addAlpha(Theme.options.red, 0.18)

        RowLayout {
          anchors.centerIn: parent
          spacing: 3

          Rectangle {
            width: 7
            height: 7
            radius: 3.5
            color: Theme.options.red

            SequentialAnimation on opacity {
              running: true
              loops: Animation.Infinite
              NumberAnimation { to: 0.3; duration: 800; easing.type: Easing.InOutQuad }
              NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutQuad }
            }
          }
        }
      }
    }
  }

  // Wireguard
  Loader {
    id: wireguard

    Layout.alignment: Qt.AlignHCenter
    property bool isActive: SWireguard.isActive
    active: isActive
    visible: isActive
    sourceComponent: Component {
      MaterialIcon {
        icon: "vpn_lock"
        size: ConfigVBar.statusIconSize
        weight: Font.Normal
        color: Theme.options.green
      }
    }
  }
}
