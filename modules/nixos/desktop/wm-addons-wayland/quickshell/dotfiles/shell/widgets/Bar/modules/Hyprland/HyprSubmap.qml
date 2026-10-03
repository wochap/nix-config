import QtQuick
import qs.config
import qs.services
import qs.widgets.common
import qs.widgets.Bar.modules

Loader {
  id: root

  // The window switcher's internal submap is not a user-facing mode.
  readonly property bool shown: SHyprland.submap.length > 0 && !SHyprland.submap.startsWith("window-switcher")

  active: root.shown
  visible: root.shown
  sourceComponent: Component {
    Module {
      label: SHyprland.submap.toUpperCase()
      fgColor: Theme.options.peach
    }
  }
}
