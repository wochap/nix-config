import qs.config
import qs.services

HyprClientCount {
  id: root

  property string namespace: ""
  icon: " "
  label: `Special workspace ${root.namespace}`
  clients: SHyprland.clients.filter(client => client.workspace.name === "special:" + root.namespace)
}
