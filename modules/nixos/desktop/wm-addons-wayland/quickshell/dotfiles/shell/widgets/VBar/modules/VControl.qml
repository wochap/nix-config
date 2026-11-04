import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.services
import qs.widgets.common
import qs.widgets.VBar.config
import qs.Woints

Rectangle {
  id: root

  property bool isHovered: false

  implicitWidth: 36
  implicitHeight: col.implicitHeight + 12
  radius: 18
  color: root.isHovered ? Theme.options.surface1 : SControlCenter.isOpen ? Theme.options.surface0 : "transparent"
  border.width: SControlCenter.isOpen ? 1 : 0
  border.color: Theme.options.primary

  ColumnLayout {
    id: col

    anchors.centerIn: parent
    spacing: 6

    SystemIcon {
      Layout.alignment: Qt.AlignHCenter
      icon: SBluetooth.icon
      size: 22
      enableColoriser: true
      color: SBluetooth.iconColor
    }

    SystemIcon {
      Layout.alignment: Qt.AlignHCenter
      icon: SNetwork.icon
      size: 22
      enableColoriser: true
      color: SNetwork.iconColor
    }

    SystemIcon {
      Layout.alignment: Qt.AlignHCenter
      icon: SPipewire.outputIcon
      size: 22
      enableColoriser: true
      color: SPipewire.outputIconColor
    }

    SystemIcon {
      Layout.alignment: Qt.AlignHCenter
      icon: SPipewire.inputIcon
      size: 22
      enableColoriser: true
      color: SPipewire.inputIconColor
    }

    SystemIcon {
      Layout.alignment: Qt.AlignHCenter
      icon: SPowerProfiles.icon
      size: 22
      enableColoriser: true
      color: SPowerProfiles.iconColor
    }

    ColumnLayout {
      Layout.alignment: Qt.AlignHCenter
      visible: SUpower.available
      spacing: 0

      SystemIcon {
        Layout.alignment: Qt.AlignHCenter
        icon: SUpower.batteryIcon
        size: 22
        enableColoriser: true
        color: SUpower.batteryIconColor
      }

      StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: Math.round(SUpower.percentage * 100).toString()
        font.pixelSize: 10
        color: Theme.options.text
      }
    }
  }

  HoverHandler {
    onHoveredChanged: root.isHovered = hovered
  }

  MouseArea {
    id: mouseArea

    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton
    Accessible.role: Accessible.Button
    Accessible.name: "Control center"
    Accessible.checkable: true
    Accessible.checked: SControlCenter.isOpen
    Accessible.onPressAction: SControlCenter.toggle()
    onClicked: event => {
      if (event.button === Qt.LeftButton) {
        SControlCenter.toggle();
      }
      event.accepted = true;
    }

    Hintable {
      label: "Control center"
      onActivated: SControlCenter.toggle()
    }
  }
}
