import Quickshell
import Quickshell.Hyprland
import QtQuick
import qs.services
import "../../Bar/modules/Hyprland/Utils.js" as Utils

Scope {
  id: root

  property bool isOpen: false
  property bool pendingConfirm: false
  property var mru: []
  property string selectedId: ""
  property string openedFrom: ""
  property string mode: "all"

  readonly property real focusedMonitorAspect: {
    const width = Hyprland.focusedMonitor?.width ?? 16;
    const height = Hyprland.focusedMonitor?.height ?? 9;
    return height > 0 ? width / height : 16.0 / 9.0;
  }

  readonly property var orderedToplevels: {
    const list = [...(Hyprland.focusedWorkspace?.toplevels?.values ?? [])].filter(toplevel => {
      const client = root.clientFor(toplevel?.address ?? "");
      if (!client)
        return false;
      const icon = Utils.mapAppId(client.class ?? "");
      if (Utils.isIgnoredInWorkspaces(icon, client.title))
        return false;
      if (root.mode === "floating")
        return client.floating === true;
      if (root.mode === "tiling")
        return client.floating !== true;
      return true;
    });
    const rank = toplevel => {
      const index = root.findIndex(toplevel?.address ?? "");
      return index === -1 ? root.mru.length : index;
    };
    list.sort((a, b) => rank(a) - rank(b));
    const pinned = root.isOpen ? root.openedFrom : (Hyprland.activeToplevel?.address ?? "");
    return list.filter(toplevel => (toplevel?.address ?? "") !== pinned).concat(list.filter(toplevel => (toplevel?.address ?? "") === pinned));
  }

  // Compositor-neutral data consumed by WindowSwitcherContent.
  readonly property var windows: root.orderedToplevels.map(toplevel => {
    const id = toplevel?.address ?? "";
    const client = root.clientFor(id);
    return {
      id: id,
      title: toplevel?.title ?? "",
      icon: Utils.mapAppId(client?.class ?? ""),
      captureSource: toplevel?.wayland ?? null
    };
  })

  function findIndex(id) {
    for (let i = 0; i < root.mru.length; i++) {
      if (root.mru[i] === id)
        return i;
    }
    return -1;
  }

  function clientFor(id) {
    const hyprlandAddress = id.startsWith("0x") ? id : `0x${id}`;
    return SHyprland.clientsByAddress?.[hyprlandAddress] ?? null;
  }

  function normalizedMode(requestedMode) {
    return requestedMode === "floating" || requestedMode === "tiling" ? requestedMode : "all";
  }

  function indexOfId(list, id) {
    for (let i = 0; i < list.length; i++) {
      if ((list[i]?.address ?? "") === id)
        return i;
    }
    return -1;
  }

  function pushFocus(id) {
    if (!id)
      return;
    const list = root.mru.filter(candidate => candidate !== id);
    list.unshift(id);
    root.mru = list;
  }

  function select(id) {
    root.selectedId = id;
  }

  function moveSelection(delta) {
    const list = root.orderedToplevels;
    if (list.length === 0)
      return;
    const index = root.indexOfId(list, root.selectedId);
    const next = ((index + delta) % list.length + list.length) % list.length;
    root.selectedId = list[next]?.address ?? "";
  }

  function toggle() {
    if (root.isOpen)
      root.hide();
    else
      root.show();
  }

  function show(requestedMode) {
    if (root.isOpen)
      return;
    root.mode = root.normalizedMode(requestedMode);
    root.isOpen = true;
    root.openedFrom = Hyprland.activeToplevel?.address ?? "";
    root.selectedId = root.orderedToplevels[0]?.address ?? "";
    if (root.pendingConfirm) {
      root.pendingConfirm = false;
      pendingConfirmTimer.stop();
      root.confirm();
    }
  }

  function hide() {
    root.isOpen = false;
    root.selectedId = "";
    root.openedFrom = "";
  }

  function advance(requestedMode) {
    if (!root.isOpen)
      root.show(requestedMode);
    else
      root.moveSelection(1);
  }

  function reverse(requestedMode) {
    if (!root.isOpen)
      root.show(requestedMode);
    else
      root.moveSelection(-1);
  }

  function confirm() {
    if (!root.isOpen) {
      root.pendingConfirm = true;
      pendingConfirmTimer.restart();
      return;
    }
    const id = root.selectedId;
    const known = root.indexOfId(root.orderedToplevels, id) !== -1;
    root.hide();
    if (!id || !known)
      return;
    focusTimer.address = id;
    focusTimer.restart();
  }

  Timer {
    id: pendingConfirmTimer
    interval: 300
    onTriggered: root.pendingConfirm = false
  }

  Timer {
    id: focusTimer
    interval: 50
    property string address: ""

    onTriggered: {
      if (Hyprland.usingLua)
        Hyprland.dispatch(`hl.dsp.focus({ window = "address:0x${address}" })`);
      else
        Hyprland.dispatch(`focuswindow address:0x${address}`);
    }
  }

  Connections {
    target: Hyprland

    function onRawEvent(event) {
      if (event.name === "activewindowv2" && event.data)
        root.pushFocus(event.data);
    }
  }
}
