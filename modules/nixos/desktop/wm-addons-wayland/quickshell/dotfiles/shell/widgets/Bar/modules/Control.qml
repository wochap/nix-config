import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets.common
import qs.widgets.Bar.config

BarChipButton {
  id: root

  implicitWidth: controlContent.implicitWidth + 20
  Layout.fillHeight: true
  radius: height / 2
  active: SControlCenter.isOpen
  accessibleName: "Control center"
  onClicked: SControlCenter.toggle()

  RowLayout {
    id: controlContent

    anchors.centerIn: parent
    spacing: 6

    SystemIcon {
      icon: SBluetooth.icon
      size: 22
      enableColoriser: true
      color: SBluetooth.iconColor
    }

    SystemIcon {
      icon: SNetwork.icon
      size: 22
      enableColoriser: true
      color: SNetwork.iconColor
    }

    SystemIcon {
      icon: SPipewire.outputIcon
      size: 22
      enableColoriser: true
      color: SPipewire.outputIconColor
    }

    SystemIcon {
      icon: SPipewire.inputIcon
      size: 22
      enableColoriser: true
      color: SPipewire.inputIconColor
    }

    SystemIcon {
      icon: SPowerProfiles.icon
      size: 22
      enableColoriser: true
      color: SPowerProfiles.iconColor
    }

    RowLayout {
      visible: SUpower.available
      spacing: 2

      SystemIcon {
        icon: SUpower.batteryIcon
        size: 22
        enableColoriser: true
        color: SUpower.batteryIconColor
      }

      StyledText {
        text: Math.round(SUpower.percentage * 100).toString()
        font.pixelSize: 10
        color: Theme.options.text
      }
    }
  }
}
