pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell

Singleton {
  id: root

  property bool isOpen: false

  function toggle() {
    root.isOpen = !root.isOpen;
  }
}
