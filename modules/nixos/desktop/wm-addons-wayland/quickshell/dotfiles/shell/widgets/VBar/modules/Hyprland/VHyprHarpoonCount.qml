import qs.config
import qs.services

VHyprClientCount {
  id: root

  property string tagPrefix: ""
  property string excludedTagPrefix: ""
  materialIcon: "push_pin"
  label: "Harpoon"

  function hasTagPrefix(client, prefix) {
    return prefix.length > 0 && (client.tags ?? []).some(tag => tag.startsWith(prefix));
  }

  bindingForClient: client => {
    const tag = (client.tags ?? []).find(tag => tag.startsWith(root.tagPrefix));
    return tag?.charAt(root.tagPrefix.length) ?? "";
  }

  clients: SHyprland.clients.filter(client => root.hasTagPrefix(client, root.tagPrefix)
      && !root.hasTagPrefix(client, root.excludedTagPrefix))
}
