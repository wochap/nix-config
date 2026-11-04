import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.widgets.common
import qs.widgets.VBar.config

Loader {
  id: root

  required property var clients
  property string fgColor: Theme.options.lavender
  property string icon: ""
  property string materialIcon: ""
  property string label: ""
  property var bindingForClient: client => ""
  readonly property int count: root.clients.length

  active: root.count > 0
  visible: root.count > 0
  sourceComponent: Component {
    BarChipButton {
      id: button

      implicitWidth: 36
      implicitHeight: chip.implicitHeight + 10
      radius: ConfigVBar.trayButtonRadius
      active: popup.isOpen
      accessibleName: `${root.label}: ${root.count} ${root.count === 1 ? "window" : "windows"}`
      onClicked: popup.toggle()

      StatusBadge {
        id: chip

        anchors.centerIn: parent
        vertical: true
        itemSpacing: 1
        icon: root.materialIcon
        woosIcon: root.icon
        iconColor: root.fgColor
        iconSize: ConfigVBar.statusIconSize
        text: root.count.toString()
        fontSize: ConfigVBar.statusFontSize
      }

      HyprClientListPopup {
        id: popup

        anchorItem: button
        anchor.edges: Edges.Right | Edges.Top
        anchor.gravity: Edges.Right | Edges.Bottom
        anchor.margins.right: 2
        anchor.margins.top: -12
        label: root.label
        clients: root.clients
        bindingForClient: root.bindingForClient
      }
    }
  }
}
