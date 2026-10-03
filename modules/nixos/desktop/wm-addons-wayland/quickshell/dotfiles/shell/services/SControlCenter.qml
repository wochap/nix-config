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

  // raise (or launch) a TUI scratchpad through the Hyprland lua scratchpad lib,
  // same behavior as the binds in the `tui` submap
  function openScratchpad(name) {
    root.close();
    const lua = `local c = require("hyprland.constants"); require("hyprland.lib.scratchpad").raise_or_run("${name}", "${name}", (not c.is_kiosk) and { use_uwsm = true } or nil)`;
    Quickshell.execDetached(["hyprctl", "eval", lua]);
  }

  // session actions, same commands as tofi-powermenu
  function runSessionAction(action) {
    const commands = {
      lock: "loginctl lock-session",
      suspend: "systemctl suspend",
      logout: "uwsm stop",
      reboot: "systemctl reboot",
      poweroff: "systemctl poweroff --check-inhibitors=no"
    };
    const command = commands[action];
    if (!command) {
      return;
    }
    root.close();
    Quickshell.execDetached(["bash", "-c", command]);
  }
}
