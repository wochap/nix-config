import QtQuick
import QtQuick.Layouts
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
    RowLayout {
      spacing: 4

      MaterialIcon {
        icon: "vpn_lock"
        size: ConfigBar.statusIconSize
        weight: Font.Normal
        color: Theme.options.green
      }

      StyledText {
        visible: root.ip.length > 0
        text: root.ip
        font.pixelSize: ConfigBar.statusFontSize
        font.weight: 600
        color: Theme.options.subtext1
      }
    }
  }
}

