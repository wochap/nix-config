import QtQuick
import qs.config
import qs.services
import qs.widgets.common
import qs.widgets.Bar.config

Loader {
  id: root

  property int unread: SMail.unread
  property bool isVisible: unread > 0

  active: isVisible
  visible: isVisible
  sourceComponent: Component {
    Module {
      materialIcon: "mail"
      iconSize: Styles.font.pixelSize.huge
      label: root.unread.toString()
      paddingX: 0
      bgColor: "transparent"
      fgColor: Theme.options.blue
    }
  }
}
