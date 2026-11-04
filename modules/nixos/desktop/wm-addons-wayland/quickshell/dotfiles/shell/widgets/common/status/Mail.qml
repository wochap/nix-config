import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets.common

StatusModule {
  id: root

  property int unread: SMail.unread

  isVisible: root.unread > 0
  sourceComponent: Component {
    StatusBadge {
      vertical: root.vertical
      icon: "mail"
      iconColor: Theme.options.blue
      iconSize: root.iconSize
      text: root.unread.toString()
      fontSize: root.fontSize
    }
  }
}
