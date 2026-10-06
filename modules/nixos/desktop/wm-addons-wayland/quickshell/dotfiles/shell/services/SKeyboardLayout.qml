pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// active xkb layout of the main keyboard, e.g. "us" out of "us,ru"
Singleton {
  id: root

  property var layouts: []
  property int index: 0
  readonly property string current: root.layouts[root.index] ?? ""
  // the first layout in the list is the default one
  readonly property bool isDefault: root.index === 0

  function refresh() {
    devicesProcess.running = true;
  }

  Component.onCompleted: root.refresh()

  Connections {
    target: Hyprland

    // data is "<keyboard>,<layout description>", the description doesn't map
    // back to a code, so re-read the index from hyprctl
    function onRawEvent(event) {
      if (event.name === "activelayout") {
        root.refresh();
      }
    }
  }

  Process {
    id: devicesProcess

    command: ["hyprctl", "devices", "-j"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const keyboards = JSON.parse(text).keyboards ?? [];
          const keyboard = keyboards.find(k => k.main) ?? keyboards[0];
          if (!keyboard) {
            return;
          }
          root.layouts = (keyboard.layout ?? "").split(",").map(l => l.trim()).filter(Boolean);
          root.index = Math.max(0, keyboard.active_layout_index ?? 0);
        } catch (e) {
          root.layouts = [];
          root.index = 0;
        }
      }
    }
  }
}
