import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.services
import qs.widgets.Lock

// session lock owned by the resident lock instance (lock.qml)
Scope {
  id: root

  WlSessionLock {
    id: sessionLock

    locked: SLockSession.isLocked

    LockSurface {}
  }

  // `loginctl lock-session` (keybind, before sleep, idle)
  Connections {
    target: SLock

    function onIsLockChanged() {
      if (SLock.isLock) {
        SLockSession.lock();
      }
    }
  }

  IpcHandler {
    target: "lock"

    function lock(): void {
      SLockSession.lock();
    }

    function isLocked(): bool {
      return SLockSession.isLocked;
    }

    // escape hatch while developing, ignored unless QS_LOCK_DEV=1
    function unlock(): void {
      if (Quickshell.env("QS_LOCK_DEV") === "1") {
        SLockSession.forceUnlock();
      }
    }
  }
}
