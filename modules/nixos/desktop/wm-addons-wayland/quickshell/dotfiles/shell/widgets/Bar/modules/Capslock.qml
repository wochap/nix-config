import QtQuick

import qs.config
import qs.services
import qs.widgets.common
import qs.widgets.Bar.config

Loader {
  id: root

  property bool isLock: SCapslock.isLock
  property bool isVisible: isLock

  active: isVisible
  visible: isVisible
  sourceComponent: Component {
    MaterialIcon {
      icon: "keyboard_capslock_badge"
      size: Styles.font.pixelSize.huge
      color: Theme.options.peach
    }
  }
}
