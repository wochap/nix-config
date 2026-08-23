pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland

// Owns the window switcher state and keeps a most-recently-focused (MRU) history.
// Tracks Hyprland's `activewindowv2` events continuously so the ordering is
// ready by the time the switcher is opened.
Singleton {
  id: root

  property bool isOpen: false
  // A `confirm` arrived while closed (race with a still-inflight `advance`).
  property bool pendingConfirm: false
  property var mru: []
  // Address of the currently selected toplevel while open.
  property string selectedAddress: ""
  // Address of the window that was focused when the switcher opened. It is
  // pinned to the end of the ordered list so entry 0 is the previous window.
  property string openedFrom: ""

  function findIndex(address) {
    for (let i = 0; i < root.mru.length; i++) {
      if (root.mru[i] === address)
        return i;
    }
    return -1;
  }

  // Move the given window to the front of the focus history.
  function pushFocus(address) {
    if (!address)
      return;
    const list = root.mru.filter(a => a !== address);
    list.unshift(address);
    root.mru = list;
  }

  // Toplevels of the focused workspace in most-recently-focused order, with
  // the window the switcher was opened from pinned to the end. The first
  // entry (index 0) is therefore the previous window Alt+Tab should switch
  // to, so releasing right at open switches there.
  readonly property var orderedToplevels: {
    const list = [...(Hyprland.focusedWorkspace?.toplevels?.values ?? [])];
    const rank = toplevel => {
      const index = root.findIndex(toplevel?.address ?? "");
      return index === -1 ? root.mru.length : index;
    };
    list.sort((a, b) => rank(a) - rank(b));
    const pinned = root.isOpen ? root.openedFrom : (Hyprland.activeToplevel?.address ?? "");
    return list.filter(toplevel => (toplevel?.address ?? "") !== pinned).concat(list.filter(toplevel => (toplevel?.address ?? "") === pinned));
  }

  function indexOfAddress(list, address) {
    for (let i = 0; i < list.length; i++) {
      if ((list[i]?.address ?? "") === address)
        return i;
    }
    return -1;
  }

  function moveSelection(delta) {
    const list = root.orderedToplevels;
    if (list.length === 0)
      return;
    const index = root.indexOfAddress(list, root.selectedAddress);
    const next = ((index + delta) % list.length + list.length) % list.length;
    root.selectedAddress = list[next]?.address ?? "";
  }

  function advance() {
    if (!root.isOpen) {
      root.show();
    } else {
      root.moveSelection(1);
    }
  }

  function reverse() {
    if (!root.isOpen) {
      root.show();
    } else {
      root.moveSelection(-1);
    }
  }

  // Alt+Tab tapped faster than the `advance` ipc can arrive: the `confirm`
  // ipc (spawned as a separate process on Alt release) lands while still
  // closed. Arm a short grace period instead of dropping it; the pending
  // confirm then fires the moment the switcher opens.
  Timer {
    id: pendingConfirmTimer
    interval: 300
    onTriggered: root.pendingConfirm = false
  }

  // Hyprland refuses window focus while an exclusive layer surface (this
  // switcher) holds the keyboard, but still warps the cursor to the target —
  // leaving the cursor on the target and focus on the previous window. Delay
  // the dispatch until the overlay surface is gone.
  Timer {
    id: focusTimer
    interval: 50
    property string address: ""

    onTriggered: {
      // Hyprland lua configs evaluate `dispatch` requests as lua expressions
      // (`return hl.dispatch(<request>)`), where classic dispatcher syntax fails.
      if (Hyprland.usingLua) {
        Hyprland.dispatch(`hl.dsp.focus({ window = "address:0x${address}" })`);
      } else {
        Hyprland.dispatch(`focuswindow address:0x${address}`);
      }
    }
  }

  // Focus the selected window and close the switcher. While closed, hold the
  // request briefly in case the matching `advance` is still in flight.
  function confirm() {
    if (!root.isOpen) {
      root.pendingConfirm = true;
      pendingConfirmTimer.restart();
      return;
    }
    const address = root.selectedAddress;
    const known = root.indexOfAddress(root.orderedToplevels, address) !== -1;
    root.hide();
    if (!address || !known)
      return;
    focusTimer.address = address;
    focusTimer.restart();
  }

  function toggle() {
    if (root.isOpen) {
      root.hide();
    } else {
      root.show();
    }
  }

  function show() {
    if (root.isOpen)
      return;
    root.isOpen = true;
    root.openedFrom = Hyprland.activeToplevel?.address ?? "";
    root.selectedAddress = root.orderedToplevels[0]?.address ?? "";
    if (root.pendingConfirm) {
      root.pendingConfirm = false;
      pendingConfirmTimer.stop();
      root.confirm();
    }
  }

  function hide() {
    root.isOpen = false;
    root.selectedAddress = "";
    root.openedFrom = "";
  }

  Connections {
    target: Hyprland

    // `activewindowv2` carries the window address (`activewindow` carries
    // class,title instead). An empty payload means focus was lost, e.g. by
    // this shell grabbing exclusive keyboard focus; ignore it so the history
    // stays intact while the switcher is open.
    function onRawEvent(event) {
      if (event.name === "activewindowv2" && event.data) {
        root.pushFocus(event.data);
      }
    }
  }
}
