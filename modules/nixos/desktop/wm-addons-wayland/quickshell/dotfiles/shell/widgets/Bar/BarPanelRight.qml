import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.services.SNotifications
import qs.widgets.common
import qs.widgets.Bar.config
import qs.widgets.Bar.modules
import qs.widgets.Bar.modules.SysTray

RowLayout {
  id: root

  required property bool isFocused

  spacing: ConfigBar.modulesSpacing

  SysTray {
    visible: isFocused
    Layout.fillHeight: true
  }

  RowLayout {
    Layout.fillHeight: true
    // HACK: MaterialIcon offset
    Layout.leftMargin: ConfigBar.modulesSpacing
    Layout.rightMargin: 0
    spacing: 0
    visible: isFocused && (capslock.isVisible || timewarrior.isVisible || idleInhibit.isVisible || agents.isVisible || mail.isVisible || offlinemsmtp.isVisible || recorder.isVisible || wireguard.isVisible || notifications.isVisible)

    Capslock {
      id: capslock

      Layout.fillHeight: true
    }

    Agents {
      id: agents

      Layout.fillHeight: true
    }

    Timewarrior {
      id: timewarrior

      Layout.fillHeight: true
    }

    Loader {
      id: notifications

      Layout.fillHeight: true
      property bool isVisible: SNotifications.isSilent
      active: isVisible
      visible: isVisible
      sourceComponent: Component {
        WoosIcon {
          icon: ""
          size: Styles.font.pixelSize.larger
          color: Theme.options.red
        }
      }
    }

    Mail {
      id: mail

      Layout.fillHeight: true
    }

    Offlinemsmtp {
      id: offlinemsmtp

      Layout.fillHeight: true
    }

    Recorder {
      id: recorder

      Layout.fillHeight: true
    }

    Wireguard {
      id: wireguard

      Layout.fillHeight: true
    }

    IdleInhibit {
      id: idleInhibit

      Layout.fillHeight: true
    }
  }

  Control {
    visible: isFocused
    Layout.fillHeight: true
  }

  // Clock, opens the calendar popover
  WrapperRectangle {
    id: clock

    property bool isHovered: false

    Layout.fillHeight: true
    leftMargin: 4
    rightMargin: 4
    color: clock.isHovered ? Theme.options.surface1 : SCalendar.isOpen ? Theme.options.surface0 : "transparent"
    radius: ConfigBar.modulesRadius

    child: Item {
      implicitWidth: clockText.implicitWidth
      implicitHeight: clockText.implicitHeight

      StyledText {
        id: clockText

        anchors.fill: parent
        text: Qt.formatDateTime(clockService.date, "ddd dd MMM HH:mm")
      }

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        onClicked: SCalendar.toggle()
      }

      HoverHandler {
        onHoveredChanged: clock.isHovered = hovered
      }
    }

    SystemClock {
      id: clockService

      precision: SystemClock.Minutes
    }
  }
}
