import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import qs.services
import ".."

Scope {
  id: root

  property var rawBindings: []
  property var dynamicHints: ({})
  property int heldModifierMask: 0
  property bool holdReady: false

  readonly property string submap: SHyprland.submap ?? ""
  readonly property var screen: Quickshell.screens.find(candidate => candidate.name === Hyprland.focusedMonitor?.name) ?? null
  readonly property var heldModifiers: root.modifierLabels(root.heldModifierMask)
  readonly property var bindings: root.filteredBindings()
  readonly property bool isOpen: root.bindings.length > 0 && (root.submap.length > 0 || (root.holdReady && root.heldModifierMask !== 0))

  function modifierLabels(mask) {
    const labels = [];
    if (mask & 64)
      // labels.push("◆ Super");
      labels.push("◆");
    if (mask & 4)
      // labels.push("⌃ Ctrl");
      labels.push("⌃");
    if (mask & 8)
      // labels.push("⌥ Alt");
      labels.push("⌥");
    if (mask & 1)
      // labels.push("⇧ Shift");
      labels.push("⇧");
    return labels;
  }

  function normalizedKey(key) {
    const value = String(key ?? "");
    const names = {
      "space": "Space",
      "return": "Enter",
      "escape": "Esc",
      "tab": "Tab",
      "backspace": "Backspace",
      "delete": "Delete",
      "left": "←",
      "right": "→",
      "up": "↑",
      "down": "↓",
      "comma": ",",
      "period": ".",
      "grave": "`",
      "bracketleft": "[",
      "bracketright": "]",
      "mouse:272": "Mouse 1",
      "mouse:273": "Mouse 2",
      "mouse:274": "Mouse 3"
    };
    return names[value.toLowerCase()] ?? value;
  }

  function isUniversal(binding) {
    return binding?.submap_universal === true || binding?.submap_universal === "true";
  }

  function isDescribed(binding) {
    return binding?.has_description === true && String(binding?.description ?? "").trim().length > 0;
  }

  function filteredBindings() {
    const activeSubmap = root.submap;
    const heldMask = root.heldModifierMask;
    const result = root.rawBindings.filter(binding => {
      if (!root.isDescribed(binding))
        return false;
      if (activeSubmap.length > 0)
        return binding?.submap === activeSubmap || root.isUniversal(binding);
      return (binding?.submap ?? "") === "" && Number(binding?.modmask ?? 0) === heldMask;
    }).map(binding => {
      const modifiers = activeSubmap.length > 0 ? root.modifierLabels(Number(binding?.modmask ?? 0)) : [];
      return {
        keycaps: modifiers.concat([root.normalizedKey(binding?.key)]),
        description: String(binding?.description ?? "")
      };
    });
    const submapHints = root.dynamicHints[activeSubmap] ?? {};
    for (const key of Object.keys(submapHints)) {
      result.push({
        keycaps: [root.normalizedKey(key)],
        description: String(submapHints[key] ?? "")
      });
    }
    result.sort((left, right) => {
      const leftKey = left.keycaps.join("+");
      const rightKey = right.keycaps.join("+");
      return leftKey.localeCompare(rightKey);
    });
    return result;
  }

  function updateHint(payload) {
    const parts = payload.split(">>");
    const action = parts[0];
    const submap = decodeURIComponent(parts[1] ?? "");
    if (submap.length === 0)
      return;

    const hints = Object.assign({}, root.dynamicHints);
    if (action === "clear") {
      delete hints[submap];
    } else {
      const key = decodeURIComponent(parts[2] ?? "");
      if (key.length === 0)
        return;
      const submapHints = Object.assign({}, hints[submap] ?? {});
      if (action === "set")
        submapHints[key] = decodeURIComponent(parts[3] ?? "");
      else if (action === "remove")
        delete submapHints[key];
      else
        return;
      hints[submap] = submapHints;
    }
    root.dynamicHints = hints;
  }

  function updateModifierMask(mask) {
    const nextMask = Number(mask);
    if (!Number.isFinite(nextMask) || nextMask < 0)
      return;
    const previousMask = root.heldModifierMask;
    root.heldModifierMask = nextMask;
    if (previousMask === 0 && nextMask !== 0) {
      root.holdReady = false;
      holdTimer.restart();
    } else if (nextMask === 0) {
      holdTimer.stop();
      root.holdReady = false;
    }
  }

  function reloadBindings() {
    if (!getBindings.running)
      getBindings.running = true;
  }

  Timer {
    id: holdTimer

    interval: ConfigWhichKeys.holdDelay
    repeat: false
    onTriggered: root.holdReady = root.heldModifierMask !== 0
  }

  Process {
    id: getBindings

    command: ["hyprctl", "binds", "-j"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const parsed = JSON.parse(text);
          if (Array.isArray(parsed))
            root.rawBindings = parsed;
        } catch (error) {
          console.warn(`WhichKeys: failed to parse hyprctl binds: ${error}`);
        }
      }
    }
  }

  Connections {
    target: Hyprland

    function onRawEvent(event) {
      if (event.name === "custom" && event.data?.startsWith("which_keys>>"))
        root.updateModifierMask(event.data.slice("which_keys>>".length));
      else if (event.name === "custom" && event.data?.startsWith("which_keys_hint>>"))
        root.updateHint(event.data.slice("which_keys_hint>>".length));
      else if (event.name === "configreloaded")
        root.reloadBindings();
    }
  }
}
