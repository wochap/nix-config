import QtQuick
import qs.config
import qs.widgets.Bar.modules

Loader {
  id: root

  required property var clients
  property string fgColor: Theme.options.lavender
  property string icon: ""
  property var bindingForClient: client => ""
  readonly property int count: root.clients.length

  active: root.count > 0
  visible: root.count > 0
  sourceComponent: Component {
    MouseArea {
      implicitWidth: module.implicitWidth
      implicitHeight: module.implicitHeight
      onClicked: popup.visible = !popup.visible

      Module {
        id: module

        anchors.fill: parent
        iconSize: Styles.font.pixelSize.normal
        fgColor: root.fgColor
        icon: root.icon
        label: root.count
      }

      HyprClientCountPopup {
        id: popup

        anchorItem: module
        clients: root.clients
        bindingForClient: root.bindingForClient
      }
    }
  }
}
