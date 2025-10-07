import Quickshell
import Quickshell.Io
import QtQuick

Scope {
  id: root

  property bool isOpen: false

  LazyLoader {
    active: isOpen
    component: ControlCenterContent {}
  }

  IpcHandler {
    target: "control-center"

    function toggle() {
      root.isOpen = !root.isOpen;
    }
  }
}
