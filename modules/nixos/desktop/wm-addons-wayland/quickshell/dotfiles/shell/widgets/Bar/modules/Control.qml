import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets.common
import qs.widgets.Bar.config
import qs.Woints

Rectangle {
  id: root

  property bool isHovered: false

  implicitWidth: controlContent.implicitWidth + 20
  Layout.fillHeight: true
  radius: height / 2
  color: root.isHovered ? Theme.options.surface1 : SControlCenter.isOpen ? Theme.options.surface0 : "transparent"
  border.width: SControlCenter.isOpen ? 1 : 0
  border.color: Theme.options.primary

  Behavior on color {
    animation: Styles.animations.colorAnimation.createObject(this)
  }

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

  HoverHandler {
    onHoveredChanged: root.isHovered = hovered
  }

  MouseArea {
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
