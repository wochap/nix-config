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
import qs.Woints

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
    spacing: ConfigBar.modulesSpacing
    visible: isFocused && (capslock.isVisible || tt.isVisible || idleInhibit.isVisible || agents.isVisible || mail.isVisible || offlinemsmtp.isVisible || recorder.isVisible || wireguard.isVisible || notifications.isVisible)

    Capslock {
      id: capslock

      Layout.fillHeight: true
    }

    Agents {
      id: agents

      Layout.fillHeight: true
    }

    // Timewarrior {
    //   id: timewarrior
    //
    //   Layout.fillHeight: true
    // }

    Tt {
      id: tt

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
          size: ConfigBar.statusIconSize
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
  Rectangle {
    id: clock

    property bool isHovered: false

    implicitWidth: clockText.implicitWidth + 20
    Layout.fillHeight: true
    radius: height / 2
    color: clock.isHovered ? Theme.options.surface1 : SCalendar.isOpen ? Theme.options.surface0 : "transparent"
    border.width: SCalendar.isOpen ? 1 : 0
    border.color: Theme.options.primary

    Behavior on color {
      animation: Styles.animations.colorAnimation.createObject(this)
    }

    StyledText {
      id: clockText

      anchors.centerIn: parent
      text: Qt.formatDateTime(clockService.date, "ddd dd MMM HH:mm")
      font.pixelSize: 12
      font.weight: 500
      color: Theme.options.text
    }

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton
      cursorShape: Qt.PointingHandCursor
      onClicked: SCalendar.toggle()
      Accessible.role: Accessible.Button
      Accessible.name: `Calendar, ${Qt.formatDateTime(clockService.date, "dddd d MMMM HH:mm")}`
      Accessible.checkable: true
      Accessible.checked: SCalendar.isOpen
      Accessible.onPressAction: SCalendar.toggle()

      Hintable {
        label: "Calendar"
        onActivated: SCalendar.toggle()
      }
    }

    HoverHandler {
      onHoveredChanged: clock.isHovered = hovered
    }

    SystemClock {
      id: clockService

      precision: SystemClock.Minutes
    }
  }
}
