import QtQuick
import qs.config
import qs.services
import qs.widgets.common
import qs.widgets.Bar.config

Loader {
  id: root

  property bool isActive: SWireguard.isActive
  property string ip: SWireguard.ip
  property bool isVisible: isActive

  active: isVisible
  visible: isVisible
  sourceComponent: Component {
    Module {
      materialIcon: "security"
      iconSize: Styles.font.pixelSize.huge
      label: ip
      paddingX: 0
      bgColor: "transparent"
      fgColor: Theme.options.mauve
    }
  }
}

