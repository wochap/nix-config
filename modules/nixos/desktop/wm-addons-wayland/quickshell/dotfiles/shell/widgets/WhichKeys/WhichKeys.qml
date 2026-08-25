pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import "backends"

Scope {
  id: root

  HyprlandWhichKeysBackend {
    id: compositorBackend
  }

  LazyLoader {
    active: compositorBackend.isOpen
    component: WhichKeysContent {
      backend: compositorBackend
    }
  }
}
