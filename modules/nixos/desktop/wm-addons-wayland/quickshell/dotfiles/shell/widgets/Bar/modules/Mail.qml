import QtQuick
import QtQuick.Layouts
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
    RowLayout {
      spacing: 4

      MaterialIcon {
        icon: "mail"
        size: ConfigBar.statusIconSize
        weight: Font.Normal
        color: Theme.options.blue
      }

      StyledText {
        text: root.unread.toString()
        font.pixelSize: ConfigBar.statusFontSize
        font.weight: 600
        color: Theme.options.subtext1
      }
    }
  }
}
