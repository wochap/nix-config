// vendored from woints integrations/quickshell, protocol v1 — keep in sync.
// Imported as `qs.Woints`: quickshell 0.3 exposes config subdirs as qs.* modules
// and synthesizes the qmldir (pragma Singleton marks SHints), so no qmldir here.
pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Registry of hintable items, exposed to woints over the `woints` IPC
// target. Protocol 1: list() -> {"protocol":1,"items":[...]},
// invoke(id, action) -> "ok" | "unknown" | "unhandled".
Singleton {
    id: root

    readonly property int protocol: 1

    property var _entries: ({})
    property int _counter: 0

    // Register `hintable` (a Hintable); returns its id `<ns>/<n>`.
    function register(hintable, opts) {
        root._counter += 1;
        const ns = (opts && opts.ns) || "window";
        const id = ns + "/" + root._counter;
        root._entries[id] = hintable;
        return id;
    }

    function unregister(id) {
        delete root._entries[id];
    }

    function _namespace(win) {
        if (!win)
            return "";
        if (win.namespace !== undefined)
            return win.namespace;
        if (win.WlrLayershell && win.WlrLayershell.namespace !== undefined)
            return win.WlrLayershell.namespace;
        return "";
    }

    // Geometry is computed here, at call time, so nothing is tracked per frame.
    function list() {
        const items = [];
        for (const id in root._entries) {
            const h = root._entries[id];
            if (!h || !h.enabled)
                continue;
            const t = h.target;
            const win = h.window;
            if (!t || !win || !t.visible || !win.visible || t.opacity <= 0)
                continue;
            const p = t.mapToItem(null, 0, 0);
            const w = t.width, ht = t.height;
            const ww = win.width, wh = win.height;
            // Clipped: fully outside its window.
            if (w < 1 || ht < 1 || p.x + w <= 0 || p.y + ht <= 0 || p.x >= ww || p.y >= wh)
                continue;
            items.push({
                id: id,
                ns: h.ns !== "" ? h.ns : root._namespace(win),
                screen: win.screen ? win.screen.name : "",
                x: p.x,
                y: p.y,
                w: w,
                h: ht,
                label: h.label,
                actions: h.actions
            });
        }
        return JSON.stringify({ protocol: root.protocol, items: items });
    }

    function invoke(id, action) {
        const h = root._entries[id];
        if (!h)
            return "unknown";
        if (h.actions.indexOf(action) < 0)
            return "unhandled";
        h.activated(action);
        return "ok";
    }

    IpcHandler {
        target: "woints"

        function list(): string {
            return root.list();
        }

        function invoke(id: string, action: string): string {
            return root.invoke(id, action);
        }
    }
}
