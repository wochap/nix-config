import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.widgets.common
import qs.widgets.Bar.config

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

      implicitWidth: chip.implicitWidth + 16
      Layout.fillHeight: true
      radius: height / 2
      active: popup.isOpen
      accessibleName: `${root.label}: ${root.count} ${root.count === 1 ? "window" : "windows"}`
      onClicked: popup.toggle()

      StatusBadge {
        id: chip

        anchors.centerIn: parent
        itemSpacing: 6
        icon: root.materialIcon
        woosIcon: root.icon
        iconColor: root.fgColor
        iconSize: ConfigBar.statusIconSize
        text: root.count.toString()
        fontSize: ConfigBar.statusFontSize
      }

      HyprClientListPopup {
        id: popup

        anchorItem: button
        anchor.edges: Edges.Bottom | Edges.Left
        anchor.gravity: Edges.Bottom | Edges.Right
        anchor.margins.left: -12
        anchor.margins.top: Math.round(ConfigBar.barHeight - 6 - (ConfigBar.barPaddingY + button.height))
        anchor.margins.bottom: 0
        label: root.label
        clients: root.clients
        bindingForClient: root.bindingForClient
      }
    }
  }
}
