import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets.common

// The horizontal bar also shows the tunnel IP
StatusModule {
  id: root

  property bool isActive: SWireguard.isActive
  property string ip: SWireguard.ip

  isVisible: root.isActive
  sourceComponent: Component {
    StatusBadge {
      vertical: root.vertical
      icon: "vpn_lock"
      iconColor: Theme.options.green
      iconSize: root.iconSize
      text: root.vertical ? "" : root.ip
      fontSize: root.fontSize
    }
  }
}
