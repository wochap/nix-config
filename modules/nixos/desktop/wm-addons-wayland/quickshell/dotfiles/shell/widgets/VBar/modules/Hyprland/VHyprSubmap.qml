import QtQuick
import qs.config
import qs.services
import qs.widgets.common
import qs.widgets.VBar.config

Loader {
  id: root

  readonly property bool shown: SHyprland.submap.length > 0 && !SHyprland.submap.startsWith("window-switcher")

  active: root.shown
  visible: root.shown
  sourceComponent: Component {
    Rectangle {
      id: submapRect

      implicitWidth: 36
      implicitHeight: textWrapper.implicitHeight + 12
      radius: 6
      color: Theme.options.peach

      Item {
        id: textWrapper

        anchors.centerIn: parent
        implicitWidth: submapText.implicitHeight
        implicitHeight: submapText.implicitWidth

        StyledText {
          id: submapText

          anchors.centerIn: parent
          rotation: 270
          text: SHyprland.submap.toUpperCase()
          color: Theme.options.crust
          font.weight: 700
          horizontalAlignment: Text.AlignHCenter
        }
      }
    }
  }
}
