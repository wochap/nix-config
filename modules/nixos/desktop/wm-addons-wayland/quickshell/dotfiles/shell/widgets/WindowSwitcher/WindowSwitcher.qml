import Quickshell
import Quickshell.Io
import QtQuick
import "backends"

// Quickshell window switcher.
//
// The compositor maps its window-switcher bindings to the IPC methods below:
//   - if the switcher is closed, `advance` opens it (selection = previous window)
//   - if it is already open, `advance` moves the selection to the next window
// Repeating the binding cycles while its modifier is held. Releasing that
// modifier calls `confirm`, which focuses the selected window and closes the
// switcher; Enter and tile clicks also confirm, while Escape or clicking
// outside cancels.

Scope {
  id: root

  HyprlandWindowSwitcherBackend {
    id: compositorBackend
  }

  LazyLoader {
    id: loader
    active: compositorBackend.isOpen
    component: WindowSwitcherContent {
      backend: compositorBackend
    }
  }

  IpcHandler {
    target: "window-switcher"

    function toggle() {
      compositorBackend.toggle();
    }

    function show(mode: string, sessionId: string) {
      compositorBackend.show(mode, sessionId);
    }

    function hide() {
      compositorBackend.hide();
    }

    function advance(mode: string, sessionId: string) {
      compositorBackend.advance(mode, sessionId);
    }

    function reverse(mode: string, sessionId: string) {
      compositorBackend.reverse(mode, sessionId);
    }

    function confirm(sessionId: string) {
      compositorBackend.confirm(sessionId);
    }
  }
}
