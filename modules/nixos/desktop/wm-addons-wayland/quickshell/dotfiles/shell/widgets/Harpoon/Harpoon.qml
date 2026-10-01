import Quickshell
import QtQuick
import qs.services
import "backends"

Scope {
  id: root

  HyprlandHarpoonBackend {
    id: compositorBackend
  }

  LazyLoader {
    // Keep the content alive so it can retain its last model while fading out.
    // Recreate it when the output disappears: the compositor closes the layer
    // surface with its output and Quickshell never remaps it.
    active: SHyprland.focusedScreen !== null
    component: HarpoonContent {
      backend: compositorBackend
    }
  }
}
