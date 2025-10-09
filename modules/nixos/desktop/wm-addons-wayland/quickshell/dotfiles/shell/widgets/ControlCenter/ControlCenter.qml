import Quickshell
import Quickshell.Io
import QtQuick
import qs.services

Scope {
  id: root

  LazyLoader {
    active: SControlCenter.isOpen
    component: ControlCenterContent {}
  }

  IpcHandler {
    target: "control-center"

    function toggle() {
      SControlCenter.toggle();
    }
  }
}
