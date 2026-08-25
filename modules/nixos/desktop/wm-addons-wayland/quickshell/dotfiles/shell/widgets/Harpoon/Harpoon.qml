import Quickshell
import QtQuick
import "backends"

Scope {
  id: root

  HyprlandHarpoonBackend {
    id: compositorBackend
  }

  LazyLoader {
    // Keep the content alive so it can retain its last model while fading out.
    active: true
    component: HarpoonContent {
      backend: compositorBackend
    }
  }
}
