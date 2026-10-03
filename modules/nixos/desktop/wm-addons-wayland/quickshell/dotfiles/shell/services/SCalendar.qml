pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell

Singleton {
  id: root

  property bool isOpen: false
  // A click on the bar clock first clears the popover focus grab (closing it),
  // then reaches the clock and would reopen it; ignore toggles right after a close.
  property double closedAt: 0

  function toggle() {
    if (!root.isOpen && Date.now() - root.closedAt < 300)
      return;
    root.isOpen = !root.isOpen;
    if (!root.isOpen)
      root.closedAt = Date.now();
  }

  function close() {
    if (!root.isOpen)
      return;
    root.isOpen = false;
    root.closedAt = Date.now();
  }
}
