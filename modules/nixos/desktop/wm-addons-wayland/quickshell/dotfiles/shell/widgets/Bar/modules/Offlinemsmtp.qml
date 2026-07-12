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
      icon: "forward_to_inbox"
      size: Styles.font.pixelSize.huge
      color: Theme.options.blue
    }
  }
}
