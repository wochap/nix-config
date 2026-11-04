import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets.common

// Horizontal: coloured system icon. Vertical: peach pill.
StatusModule {
  id: root

  property bool isLock: SCapslock.isLock

  isVisible: root.isLock
  sourceComponent: root.vertical ? pillComponent : iconComponent

  Component {
    id: iconComponent

    SystemIcon {
      enableColoriser: true
      icon: "capslock-enabled-symbolic"
      size: Styles.font.pixelSize.hugeass
      color: Theme.options.peach
    }
  }

  Component {
    id: pillComponent

    Rectangle {
      implicitWidth: 36
      implicitHeight: 22
      radius: 11
      color: Theme.addAlpha(Theme.options.peach, 0.18)

      MaterialIcon {
        anchors.centerIn: parent
        icon: "keyboard_capslock"
        size: 17
        weight: Font.Normal
        color: Theme.options.peach
      }
    }
  }
}
