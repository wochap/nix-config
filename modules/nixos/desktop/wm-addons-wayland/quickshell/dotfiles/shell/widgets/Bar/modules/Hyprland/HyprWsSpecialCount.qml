import QtQuick
import qs.config
import qs.services
import qs.widgets.Bar.modules

Loader {
  id: root

  property string fgColor: Theme.options.lavender
  property string namespace: ""
  readonly property var clients: SHyprland.clients.filter(client => client.workspace.name === "special:" + root.namespace)
  readonly property int count: root.clients.length

  active: root.count > 0
  visible: root.count > 0
  sourceComponent: Component {
    MouseArea {
      id: clickArea

      implicitWidth: module.implicitWidth
      implicitHeight: module.implicitHeight
      onClicked: popup.visible = !popup.visible

      Module {
        id: module

        anchors.fill: parent
        iconSize: Styles.font.pixelSize.normal
        fgColor: root.fgColor
        icon: " "
        label: root.count
      }

      HyprWsSpecialCountPopup {
        id: popup

        anchorItem: module
        clients: root.clients
      }
    }
  }
}
