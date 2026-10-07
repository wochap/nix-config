import QtQuick
import QtQuick.Layouts
import qs.config
import qs.widgets.common
import qs.widgets.ControlCenter
import qs.Woints

// 2-column toggle tile: icon well, label + optional sub-label, optional chevron zone
Item {
  id: root

  property string icon: ""
  property string iconSystem: ""
  required property string label
  property string sublabel: ""
  property bool isActive: false
  property bool hasChevron: false
  readonly property bool isHovered: bodyMouseArea.containsMouse || chevronMouseArea.containsMouse
  readonly property bool isPressed: bodyMouseArea.pressed

  signal clicked
  signal chevronClicked

  implicitHeight: ConfigControlCenter.tileHeight
  opacity: root.enabled ? 1 : ConfigControlCenter.disabledOpacity

  StyledRect {
    id: background

    anchors.fill: parent
    radius: height / 2
    color: {
      const base = Theme.options.background;
      if (root.enabled && root.isPressed) {
        return Theme.tint(base, Theme.options.primary, ConfigControlCenter.tilePressedTint);
      }
      if (root.isActive) {
        return Theme.tint(base, Theme.options.primary, root.enabled && root.isHovered ? ConfigControlCenter.tileOnHoverTint : ConfigControlCenter.tileOnTint);
      }
      if (root.enabled && root.isHovered) {
        return Theme.tint(base, Theme.options.text, ConfigControlCenter.tileOffHoverTint);
      }
      return Theme.options.surface0;
    }
  }

  MouseArea {
    id: bodyMouseArea

    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
    Accessible.role: Accessible.Button
    Accessible.name: root.label
    Accessible.description: root.sublabel
    Accessible.checkable: true
    Accessible.checked: root.isActive
    Accessible.onPressAction: root.clicked()

    Hintable {
      label: root.label
      onActivated: root.clicked()
    }
  }

  RowLayout {
    anchors {
      fill: parent
      leftMargin: 4
      rightMargin: root.hasChevron ? 2 : 4
    }
    spacing: 8

    StyledRect {
      id: iconWell

      readonly property string iconColor: root.isActive || root.isPressed ? Theme.options.crust : root.enabled && root.isHovered ? Theme.options.text : Theme.options.subtext1

      Layout.preferredWidth: ConfigControlCenter.tileIconSize
      Layout.preferredHeight: ConfigControlCenter.tileIconSize
      radius: width / 2
      color: {
        if (root.enabled && root.isPressed) {
          return Theme.options.lavender;
        }
        if (root.isActive) {
          return Theme.options.primary;
        }
        return root.enabled && root.isHovered ? Theme.options.surface2 : Theme.options.surface1;
      }

      MaterialIcon {
        anchors.centerIn: parent
        visible: root.icon.length > 0
        icon: root.icon
        size: 17
        weight: Font.Normal
        color: iconWell.iconColor
      }

      SystemIcon {
        anchors.centerIn: parent
        visible: root.iconSystem.length > 0
        enableColoriser: true
        icon: root.iconSystem
        size: Styles.font.pixelSize.hugeass
        color: iconWell.iconColor
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      Layout.minimumWidth: 0
      spacing: 0

      StyledText {
        Layout.fillWidth: true
        text: root.label
        elide: Text.ElideRight
        font.pixelSize: Styles.font.pixelSize.small
        font.weight: Font.Medium
        lineHeight: 14
        lineHeightMode: Text.FixedHeight
        color: root.isActive || (root.enabled && root.isHovered) ? Theme.options.text : Theme.options.subtext1
      }

      StyledText {
        Layout.fillWidth: true
        visible: root.sublabel !== ""
        text: root.sublabel
        elide: Text.ElideRight
        font.pixelSize: Styles.font.pixelSize.smaller
        lineHeight: 13
        lineHeightMode: Text.FixedHeight
        color: root.isActive ? Theme.options.primary : root.enabled && root.isHovered ? Theme.options.subtext0 : Theme.options.overlay1
      }
    }

    // chevron zone, opens the device TUI instead of toggling
    Item {
      visible: root.hasChevron
      Layout.preferredWidth: 24
      Layout.preferredHeight: ConfigControlCenter.tileIconSize

      Rectangle {
        anchors {
          left: parent.left
          top: parent.top
          bottom: parent.bottom
        }
        width: 1
        color: root.isActive ? Theme.addAlpha(Theme.options.primary, Styles.tint.selected) : Theme.options.surface1
      }

      MaterialIcon {
        anchors.centerIn: parent
        icon: "chevron_right"
        size: 16
        weight: Font.Normal
        color: chevronMouseArea.containsMouse ? Theme.options.text : root.isActive ? Theme.options.primary : Theme.options.overlay1
      }

      MouseArea {
        id: chevronMouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.chevronClicked()
        Accessible.role: Accessible.Button
        Accessible.name: `${root.label} settings`
        Accessible.onPressAction: root.chevronClicked()

        Hintable {
          label: `${root.label} settings`
          onActivated: root.chevronClicked()
        }
      }
    }
  }
}
