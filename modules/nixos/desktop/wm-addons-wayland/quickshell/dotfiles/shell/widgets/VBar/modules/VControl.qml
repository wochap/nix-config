import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.services
import qs.widgets.common
import qs.widgets.VBar.config

BarChipButton {
  id: root

  implicitWidth: 36
  implicitHeight: col.implicitHeight + 12
  radius: 18
  active: SControlCenter.isOpen
  animateColor: false
  accessibleName: "Control center"
  onClicked: SControlCenter.toggle()

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
}
