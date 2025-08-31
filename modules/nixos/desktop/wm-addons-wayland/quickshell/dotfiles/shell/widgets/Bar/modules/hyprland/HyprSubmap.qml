import QtQuick

import qs.config
import qs.services
import qs.widgets.common
import qs.widgets.Bar.modules

Loader {
  id: root

  active: SHyprland.submap.length > 0
  visible: SHyprland.submap.length > 0
  sourceComponent: Component {
    Module {
      label: SHyprland.submap.toUpperCase()
      fgColor: Theme.options.peach
    }
  }
}
