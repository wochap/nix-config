pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
  id: root

  property bool isActive: false
  property bool isRestarting: false

  // wvkbd takes colors as rrggbb[aa], without the #
  function hex(color) {
    return String(color).replace("#", "");
  }

  function enable() {
    root.isActive = true;
    keyboard.running = true;
  }

  function disable() {
    root.isActive = false;
    keyboard.running = false;
  }

  function toggle() {
    if (root.isActive) {
      disable();
    } else {
      enable();
    }
  }

  Process {
    id: keyboard

    command: ["wvkbd-deskintl", "-L", "320", "-H", "320", "-R", "6", "--fn", `${Styles.font.family.main} 14`, "--bg", root.hex(Theme.options.mantle), "--fg", root.hex(Theme.options.surface0), "--fg-sp", root.hex(Theme.options.surface1), "--press", root.hex(Theme.options.primary), "--press-sp", root.hex(Theme.options.primary), "--swipe", root.hex(Theme.options.surface2), "--swipe-sp", root.hex(Theme.options.surface2), "--text", root.hex(Theme.options.text), "--text-sp", root.hex(Theme.options.text)]
    onExited: {
      if (root.isRestarting) {
        root.isRestarting = false;
        Qt.callLater(() => keyboard.running = true);
      } else {
        // closed outside the shell or crashed
        root.isActive = false;
      }
    }
  }

  // colors are read at launch, relaunch to follow a theme switch
  Connections {
    target: Theme

    function onChanged() {
      if (root.isActive && keyboard.running) {
        root.isRestarting = true;
        keyboard.running = false;
      }
    }
  }
}
