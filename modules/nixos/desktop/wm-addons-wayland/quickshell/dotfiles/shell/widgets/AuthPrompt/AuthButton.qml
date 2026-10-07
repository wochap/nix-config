import QtQuick
import qs.config
import qs.widgets.common
import qs.widgets.AuthPrompt
import qs.Woints

// 32px dialog button: primary (filled, Enter), secondary (Esc), ghost (risky, never default),
// tinted (outlined `tint`, e.g. the lock screen's red confirm)
FocusScope {
  id: root

  required property string label
  property string kind: "secondary"
  property string keycap: ""
  property bool isBusy: false
  property color tint: Theme.options.red
  // focus ring color
  property color ink: ConfigAuth.ink
  property int labelSize: ConfigAuth.bodySize
  readonly property bool isPrimary: root.kind === "primary"
  readonly property bool isGhost: root.kind === "ghost"
  readonly property bool isTinted: root.kind === "tinted"
  readonly property bool isHovered: mouseArea.containsMouse
  readonly property bool isPressed: mouseArea.pressed

  signal clicked

  implicitWidth: row.implicitWidth + 14 + (root.keycap ? 6 : 14)
  implicitHeight: ConfigAuth.buttonHeight
  activeFocusOnTab: root.enabled
  opacity: root.enabled ? 1 : 0.5
  Accessible.role: Accessible.Button
  Accessible.name: root.label
  Accessible.onPressAction: root.clicked()

  Keys.onSpacePressed: root.clicked()

  // focus ring: 2px gap + 2px ink
  StyledRect {
    anchors {
      fill: parent
      margins: -4
    }
    visible: root.activeFocus
    radius: ConfigAuth.controlRadius + 4
    border.width: 2
    border.color: root.ink
  }

  StyledRect {
    id: background

    anchors.fill: parent
    radius: ConfigAuth.controlRadius
    border.width: 1
    color: {
      if (root.isPrimary) {
        return root.isPressed ? ConfigAuth.inkPressed : root.isHovered ? ConfigAuth.inkHover : ConfigAuth.ink;
      }
      if (root.isGhost) {
        return root.isPressed ? Theme.options.surface1 : root.isHovered ? Theme.options.surface0 : "transparent";
      }
      if (root.isTinted) {
        return Theme.tint(Theme.options.base, String(root.tint), root.isPressed ? Styles.tint.selected : root.isHovered ? Styles.tint.hover : 0.12);
      }
      return root.isPressed ? Theme.options.surface2 : root.isHovered ? Theme.options.surface1 : Theme.options.surface0;
    }
    border.color: {
      if (root.isPrimary) {
        return background.color;
      }
      if (root.isGhost) {
        return Theme.options.surface1;
      }
      if (root.isTinted) {
        return root.tint;
      }
      return root.isPressed || root.isHovered ? Theme.options.surface2 : Theme.options.surface1;
    }
  }

  Row {
    id: row

    anchors {
      left: parent.left
      leftMargin: 14
      verticalCenter: parent.verticalCenter
    }
    spacing: 8

    MaterialIcon {
      anchors.verticalCenter: parent.verticalCenter
      visible: root.isBusy
      icon: "progress_activity"
      size: 14
      weight: Font.Bold
      color: label.color

      RotationAnimation on rotation {
        running: root.isBusy
        from: 0
        to: 360
        duration: 800
        loops: Animation.Infinite
      }
    }

    StyledText {
      id: label

      anchors.verticalCenter: parent.verticalCenter
      text: root.label
      color: root.isPrimary ? ConfigAuth.onInk : root.isTinted ? root.tint : Theme.options.text
      font.pixelSize: root.labelSize
      font.weight: Font.Medium
    }

    AuthKeycap {
      anchors.verticalCenter: parent.verticalCenter
      visible: root.keycap !== ""
      label: root.keycap
      textColor: root.isPrimary ? ConfigAuth.onInk : root.isTinted ? root.tint : ConfigAuth.subtext
      border.color: root.isPrimary ? Theme.addAlpha(String(ConfigAuth.onInk), 0.45) : root.isTinted ? Theme.addAlpha(String(root.tint), 0.5) : ConfigAuth.fieldBorder
    }
  }

  MouseArea {
    id: mouseArea

    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()

    Hintable {
      label: root.label
      onActivated: root.clicked()
    }
  }
}
