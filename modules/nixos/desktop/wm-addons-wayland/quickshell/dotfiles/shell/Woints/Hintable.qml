// vendored from woints integrations/quickshell, protocol v1 — keep in sync.
// Imported as `qs.Woints`: quickshell 0.3 exposes config subdirs as qs.* modules
// and synthesizes the qmldir (pragma Singleton marks SHints), so no qmldir here.
import QtQuick
import Quickshell

// Makes `target` (default: the parent item) hintable by woints. Zero-sized,
// never drawn; handle `onActivated` to run the action. `enabled: false`
// hides it from woints.
Item {
    id: root

    property Item target: parent
    property string label: ""
    property var actions: ["click"]
    // Layer namespace; empty reads it from the window (WlrLayershell.namespace).
    property string ns: ""

    readonly property var window: QsWindow.window
    property string _id: ""

    signal activated(string action)

    width: 0
    height: 0
    visible: false

    Component.onCompleted: {
        const n = root.ns !== "" ? root.ns : SHints._namespace(root.window);
        root._id = SHints.register(root, { ns: n });
    }
    Component.onDestruction: {
        if (root._id !== "")
            SHints.unregister(root._id);
    }
}
