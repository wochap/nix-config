import Quickshell
import Quickshell.Hyprland
import QtQuick
import qs.services
import "../../Bar/modules/Hyprland/Utils.js" as Utils

Scope {
  id: root

  readonly property string harpoonTagPrefix: "harpoon-"
  readonly property string scratchpadTagPrefix: "harpoon-scratchpad-"
  readonly property string submap: SHyprland.submap
  readonly property bool isOpen: root.submap === "harpoon" || root.submap === "scratchpad"
  readonly property real focusedMonitorAspect: {
    const width = Hyprland.focusedMonitor?.width ?? 16;
    const height = Hyprland.focusedMonitor?.height ?? 9;
    return height > 0 ? width / height : 16.0 / 9.0;
  }
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
        result.push({
          id: `${client.address}:${tag}`,
          key: tag.slice(tagPrefix.length),
          title: toplevel.title ?? client.title ?? "",
          icon: Utils.mapAppId(client.class ?? ""),
          captureSource: toplevel.wayland ?? null
        });
      }
    }
    result.sort((a, b) => a.key.localeCompare(b.key, undefined, { numeric: true }));
    return result;
  }
}
