import Quickshell
import Quickshell.Io
import QtQuick
import qs.services

Scope {
  id: root

  LazyLoader {
    // stays loaded while the exit animation runs
    active: SControlCenter.isLoaded
    component: ControlCenterContent {}
  }

  LazyLoader {
    active: SControlCenter.confirmAction !== ""
    component: SessionConfirm {}
  }

  IpcHandler {
    target: "control-center"

    function toggle() {
      SControlCenter.toggle();
    }

    function open() {
      SControlCenter.open();
    }

    function close() {
      SControlCenter.close();
    }
  }
}
