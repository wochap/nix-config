import Quickshell
import Quickshell.Io
import QtQuick
import qs.services

Scope {
  id: root

  LazyLoader {
    // stays loaded while the exit animation runs
    active: SCalendar.isLoaded
    component: CalendarContent {}
  }

  IpcHandler {
    target: "calendar"

    function toggle() {
      SCalendar.toggle();
    }

    function open() {
      SCalendar.open();
    }

    function close() {
      SCalendar.close();
    }
  }
}
