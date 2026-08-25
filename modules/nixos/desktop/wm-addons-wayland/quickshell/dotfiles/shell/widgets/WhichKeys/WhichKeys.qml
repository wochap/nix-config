pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import "backends"

Scope {
  id: root

  HyprlandWhichKeysBackend {
    id: compositorBackend
  }

  WhichKeysContent {
    backend: compositorBackend
  }
}
