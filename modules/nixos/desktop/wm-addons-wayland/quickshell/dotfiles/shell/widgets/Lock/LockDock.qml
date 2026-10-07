pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets.common
import qs.widgets.AuthPrompt
import qs.widgets.Lock

// panel toggles, bottom-right of the focused output, see design/project/LockDock.dc.html
StyledRect {
  id: root

  // bt | media | power | ""
  property string openPanel: ""

  signal toggled(string panel)

  implicitWidth: row.implicitWidth + 8
  implicitHeight: ConfigLock.railHeight
  radius: ConfigLock.radius
  color: Theme.options.mantle
  border.width: 1
  border.color: Theme.options.surface0

  component DockButton: Item {
    id: button

    required property string panel
    required property string icon
    required property string label
    required property string shortcut
    property bool isDanger: false
    readonly property bool isOpen: root.openPanel === button.panel
    readonly property bool isHovered: mouseArea.containsMouse
    property bool isTooltipShown: false

    implicitWidth: 32
    implicitHeight: 32
    activeFocusOnTab: button.enabled
    opacity: button.enabled ? 1 : ConfigLock.disabledOpacity
    Accessible.role: Accessible.Button
    Accessible.name: button.label
    Accessible.checkable: true
    Accessible.checked: button.isOpen
    Accessible.onPressAction: root.toggled(button.panel)

    Keys.onPressed: event => {
      if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
        root.toggled(button.panel);
        event.accepted = true;
      }
    }

    Timer {
      running: button.isHovered
      interval: ConfigLock.tooltipDelay
      onTriggered: button.isTooltipShown = true
    }

    onIsHoveredChanged: {
      if (!button.isHovered) {
        button.isTooltipShown = false;
      }
    }

    // focus ring: 2px mantle gap + 2px ink
    StyledRect {
      anchors {
        fill: parent
        margins: -4
      }
      visible: button.activeFocus
      radius: ConfigLock.rowRadius + 4
      border.width: 2
      border.color: ConfigLock.ink
    }

    StyledRect {
      anchors.fill: parent
      radius: ConfigLock.rowRadius
      color: {
        if (button.isOpen) {
          return Theme.addAlpha(String(ConfigLock.ink), ConfigLock.openTint);
        }
        if (mouseArea.pressed) {
          return Theme.options.surface1;
        }
        return button.isHovered ? Theme.options.surface0 : "transparent";
      }
      border.width: button.isOpen ? 1 : 0
      border.color: Theme.addAlpha(String(ConfigLock.ink), ConfigLock.openLine)
    }

    MaterialIcon {
      anchors.centerIn: parent
      icon: button.icon
      size: 18
      weight: Font.Normal
      color: {
        if (button.isOpen) {
          return ConfigLock.ink;
        }
        if (button.isDanger) {
          return Theme.options.red;
        }
        return button.isHovered ? Theme.options.text : ConfigLock.subtext;
      }
    }

    MouseArea {
      id: mouseArea

      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.toggled(button.panel)
    }

    // right-aligned, 12px above the dock
    StyledRect {
      anchors {
        right: parent.right
        bottom: parent.top
        bottomMargin: 16
      }
      opacity: (button.activeFocus || button.isTooltipShown) && !button.isOpen ? 1 : 0
      visible: opacity > 0
      implicitWidth: tooltipRow.implicitWidth + 16
      implicitHeight: tooltipRow.implicitHeight + 8
      radius: ConfigLock.radius
      color: Theme.options.base
      border.width: 1
      border.color: Theme.options.surface0

      Behavior on opacity {
        NumberAnimation {
          duration: Styles.animation.duration
          easing.type: Styles.animation.easingType
        }
      }

      RowLayout {
        id: tooltipRow

        anchors {
          left: parent.left
          leftMargin: 10
          verticalCenter: parent.verticalCenter
        }
        spacing: 8

        StyledText {
          text: button.label
          font.pixelSize: Styles.font.pixelSize.small
        }

        AuthKeycap {
          label: button.shortcut
        }
      }
    }
  }

  RowLayout {
    id: row

    anchors.centerIn: parent
    spacing: 4

    DockButton {
      panel: "bt"
      icon: "bluetooth"
      label: "Bluetooth"
      shortcut: "Alt B"
    }

    DockButton {
      panel: "media"
      icon: "music_note"
      label: "Media"
      shortcut: "Alt M"
      enabled: SMpris.available
    }

    DockButton {
      panel: "power"
      icon: "power_settings_new"
      label: "Power"
      shortcut: "Alt P"
      isDanger: true
    }
  }
}
