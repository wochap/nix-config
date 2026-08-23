import Quickshell
import Quickshell.Io
import QtQuick
import qs.services

// Quickshell window switcher.
//
// Hyprland (binds.lua) maps ALT+TAB to `ipc call window-switcher advance`:
//   - if the switcher is closed, `advance` opens it (selection = previous window)
//   - if it is already open, `advance` moves the selection to the next window
// Repeating Alt+Tab therefore cycles while Alt is held. Releasing Alt calls
// `confirm`, which focuses the selected window and closes the switcher; the
// panel itself also confirms on Alt release, Enter, or tile click, and Escape
// or clicking outside cancels.

Scope {
  id: root

  LazyLoader {
    id: loader
    active: SWindowSwitcher.isOpen
    component: WindowSwitcherContent {}
  }

  IpcHandler {
    target: "window-switcher"

    function toggle() {
      SWindowSwitcher.toggle();
    }

    function show() {
      SWindowSwitcher.show();
    }

    function hide() {
      SWindowSwitcher.hide();
    }

    function advance() {
      SWindowSwitcher.advance();
    }

    function reverse() {
      SWindowSwitcher.reverse();
    }

    function confirm() {
      SWindowSwitcher.confirm();
    }
  }
}
