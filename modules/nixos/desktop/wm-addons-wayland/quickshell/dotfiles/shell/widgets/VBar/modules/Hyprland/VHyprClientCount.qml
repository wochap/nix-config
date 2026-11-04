import QtQuick
import QtQuick.Layouts
import qs.config
import qs.widgets.common
import qs.widgets.VBar.config
import qs.Woints

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
    Rectangle {
      id: button

      property bool isHovered: false

      implicitWidth: 36
      implicitHeight: chip.implicitHeight + 10
      radius: ConfigVBar.trayButtonRadius
      color: button.isHovered ? Theme.options.surface1 : popup.isOpen ? Theme.options.surface0 : "transparent"
      border.width: popup.isOpen ? 1 : 0
      border.color: Theme.options.primary

      Behavior on color {
        animation: Styles.animations.colorAnimation.createObject(this)
      }

      HoverHandler {
        onHoveredChanged: button.isHovered = hovered
      }

      MouseArea {
        id: mouseArea

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: popup.toggle()
        Accessible.role: Accessible.Button
        Accessible.name: `${root.label}: ${root.count} ${root.count === 1 ? "window" : "windows"}`
        Accessible.checkable: true
        Accessible.checked: popup.isOpen
        Accessible.onPressAction: popup.toggle()

        Hintable {
          label: `${root.label}: ${root.count} ${root.count === 1 ? "window" : "windows"}`
          onActivated: popup.toggle()
        }
      }

      ColumnLayout {
        id: chip

        anchors.centerIn: parent
        spacing: 1

        MaterialIcon {
          Layout.alignment: Qt.AlignHCenter
          icon: root.materialIcon
          size: ConfigVBar.statusIconSize
          weight: Font.Normal
          color: root.fgColor
          visible: root.materialIcon.length > 0
        }

        WoosIcon {
          Layout.alignment: Qt.AlignHCenter
          icon: root.icon
          size: ConfigVBar.statusIconSize
          color: root.fgColor
          visible: root.icon.length > 0 && root.materialIcon.length === 0
        }

        StyledText {
          Layout.alignment: Qt.AlignHCenter
          text: root.count.toString()
          font.pixelSize: ConfigVBar.statusFontSize
          font.weight: 600
          color: Theme.options.subtext1
        }
      }

      VHyprClientCountPopup {
        id: popup

        anchorItem: button
        label: root.label
        clients: root.clients
        bindingForClient: root.bindingForClient
      }
    }
  }
}
