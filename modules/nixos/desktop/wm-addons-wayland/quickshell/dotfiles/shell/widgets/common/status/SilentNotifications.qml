import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets.common
import qs.services.SNotifications

// Shown while notifications are silenced (DND)
StatusModule {
  id: root

  isVisible: SNotifications.isSilent
  sourceComponent: Component {
    WoosIcon {
      icon: ""
      size: root.iconSize
      color: Theme.options.red
    }
  }
}
