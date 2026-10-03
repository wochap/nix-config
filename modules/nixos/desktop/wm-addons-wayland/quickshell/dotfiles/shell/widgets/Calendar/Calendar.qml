import Quickshell
import Quickshell.Io
import QtQuick
import qs.config
import qs.services

Scope {
  id: root

  // keeps the popover alive while its exit animation runs
  property bool isClosing: false

  Connections {
    target: SCalendar

    function onIsOpenChanged() {
      if (!SCalendar.isOpen) {
        root.isClosing = true;
        closingTimer.restart();
      }
    }
  }

  Timer {
    id: closingTimer

    interval: Styles.animation.exitDuration
    onTriggered: root.isClosing = false
  }

  LazyLoader {
    active: SCalendar.isOpen || root.isClosing
    component: CalendarContent {}
  }

  IpcHandler {
    target: "calendar"

    function toggle() {
      SCalendar.toggle();
    }
  }
}
