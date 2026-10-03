import QtQuick
import qs.config
import qs.services
import qs.widgets.common
import qs.widgets.Bar.config

Loader {
  id: root

  property string value: STimewarrior.value
  property bool isVisible: value.length > 0

  active: isVisible
  visible: isVisible
  sourceComponent: Component {
    Module {
      iconSystem: "appointment-soon-symbolic"
      iconSystemSize: Styles.font.pixelSize.large
      iconSize: Styles.font.pixelSize.huge
      label: value
      paddingX: 0
      bgColor: "transparent"
      fgColor: Theme.options.green
    }
  }
}
