import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets.common

StatusModule {
  id: root

  property bool isActive: SOfflinemsmtp.isActive

  isVisible: root.isActive
  sourceComponent: Component {
    MaterialIcon {
      icon: "outbox"
      size: root.iconSize
      weight: Font.Normal
      color: Theme.options.yellow
    }
  }
}
