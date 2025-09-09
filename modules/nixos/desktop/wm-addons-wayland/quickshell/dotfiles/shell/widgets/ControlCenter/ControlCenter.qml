import Quickshell
import QtQuick
import qs.services.SNotifications

Scope {
  id: root

  property bool isOpen: false

  LazyLoader {
    active: isOpen
    component: ControlCenterContent {}
  }
}
