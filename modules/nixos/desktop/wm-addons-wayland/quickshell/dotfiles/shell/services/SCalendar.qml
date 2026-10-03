pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell

Singleton {
  id: root

  // requested state, drives the enter/exit animation
  property bool isOpen: false
  // keeps the window alive until the exit animation finishes
  property bool isLoaded: false

  function open() {
    root.isLoaded = true;
    root.isOpen = true;
  }

  function close() {
    root.isOpen = false;
  }

  function toggle() {
    if (root.isOpen) {
      root.close();
    } else {
      root.open();
    }
  }

  // called by the content once the exit animation is done
  function finalizeClose() {
    if (!root.isOpen) {
      root.isLoaded = false;
    }
  }
}
