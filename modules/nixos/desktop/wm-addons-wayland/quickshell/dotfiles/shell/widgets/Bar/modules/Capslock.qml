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
    SystemIcon {
      enableColoriser: true
      icon: "capslock-enabled-symbolic"
      size: Styles.font.pixelSize.hugeass
      color: Theme.options.peach
    }
  }
}
