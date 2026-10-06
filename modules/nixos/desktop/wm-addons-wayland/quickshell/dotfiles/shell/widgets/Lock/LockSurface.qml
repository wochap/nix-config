import QtQuick
import Quickshell.Wayland
import qs.config
import qs.widgets.Lock

WlSessionLockSurface {
  id: root

  color: Theme.options.crust

  LockContent {
    anchors.fill: parent
    screen: root.screen
  }
}
