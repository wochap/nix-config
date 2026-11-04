import QtQuick
import qs.config
import qs.services
import qs.widgets.common
import qs.widgets.Bar.config

Loader {
  id: root

  property bool isActive: SOfflinemsmtp.isActive
  property bool isVisible: isActive

  active: isVisible
  visible: isVisible
  sourceComponent: Component {
    MaterialIcon {
      icon: "outbox"
      size: ConfigBar.statusIconSize
      weight: Font.Normal
      color: Theme.options.yellow
    }
  }
}
