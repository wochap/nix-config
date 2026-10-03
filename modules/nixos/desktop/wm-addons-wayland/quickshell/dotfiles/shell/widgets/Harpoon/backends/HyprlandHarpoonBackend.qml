import Quickshell
import Quickshell.Hyprland
import QtQuick
import qs.services
import "../../Bar/modules/Hyprland/Utils.js" as Utils
import "../../WindowSwitcher/WindowEntry.js" as WindowEntry

Scope {
  id: root

  readonly property string harpoonTagPrefix: "harpoon-"
  readonly property string scratchpadTagPrefix: "harpoon-scratchpad-"
  readonly property string submap: SHyprland.submap
  readonly property bool isOpen: root.submap === "harpoon" || root.submap === "scratchpad"
  readonly property var windows: {
    // Read the source submap once. Deriving the mode, prefix, and exclusions
    // from this one value avoids transient mixed modes during binding updates.
    const submap = SHyprland.submap;
    const isScratchpad = submap === "scratchpad";
    const isHarpoon = submap === "harpoon";

    // Do not fall back to the broad `harpoon-` prefix while a submap is being
    // reset. That prefix also matches scratchpads and caused both sets to flash.
    if (!isHarpoon && !isScratchpad)
      return [];
    const tagPrefix = isScratchpad ? root.scratchpadTagPrefix : root.harpoonTagPrefix;

    // Depend on both collections: tags come from hyprctl while the Wayland
    // capture source comes from Quickshell's toplevel model.
    const toplevels = [...(Hyprland.toplevels?.values ?? [])];
    const byAddress = {};
    for (const toplevel of toplevels)
      byAddress[`0x${toplevel?.address ?? ""}`] = toplevel;

    const result = [];
    for (const client of SHyprland.clients ?? []) {
      const toplevel = byAddress[client?.address ?? ""];
      if (!toplevel)
        continue;
      for (const tag of client?.tags ?? []) {
        if (!tag.startsWith(tagPrefix))
          continue;
        // Scratchpad tags share the normal harpoon prefix, so keep them out of
        // the normal harpoon submap and show them only in `scratchpad`.
        if (!isScratchpad && tag.startsWith(root.scratchpadTagPrefix))
          continue;
        result.push(WindowEntry.make(`${client.address}:${tag}`, toplevel, client, Utils.mapAppId(client.class ?? ""), {
          key: tag.slice(tagPrefix.length)
        }));
      }
    }
    result.sort((a, b) => a.key.localeCompare(b.key, undefined, { numeric: true }));
    return result;
  }

  // Focus a marked window through the compositor's harpoon module, which also
  // brings hidden special-workspace windows here, then leave the submap.
  function focus(key) {
    const module = root.submap === "scratchpad" ? "harpoon_scratchpad" : "harpoon";
    const call = root.submap === "scratchpad" ? `toggle("${key}")` : `focus("${key}")`;
    Quickshell.execDetached(["hyprctl", "eval", `require("hyprland.lib.${module}").${call}; hl.dispatch(hl.dsp.submap("reset"))`]);
  }
}
