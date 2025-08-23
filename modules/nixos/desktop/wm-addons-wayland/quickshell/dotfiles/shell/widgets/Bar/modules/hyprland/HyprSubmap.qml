import QtQuick

import qs.config
import qs.services
import qs.widgets.common
import qs.widgets.Bar.modules

Loader {
  id: root

  active: Hypr.submap.length > 0
  visible: Hypr.submap.length > 0
  sourceComponent: Component {
    Module {
      label: Hypr.submap.toUpperCase()
      fgColor: Theme.options.peach
    }
  }
}
