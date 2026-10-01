pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import "backends"

Scope {
  id: root

  HyprlandWhichKeysBackend {
    id: compositorBackend
  }

  // Recreate the window when the output disappears: the compositor closes
  // the layer surface with its output and Quickshell never remaps it.
  LazyLoader {
    active: compositorBackend.screen !== null
    component: WhichKeysContent {
      backend: compositorBackend
    }
  }
}
