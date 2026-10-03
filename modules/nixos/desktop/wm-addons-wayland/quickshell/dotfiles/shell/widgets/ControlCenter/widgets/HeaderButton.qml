import QtQuick
import qs.config
import qs.widgets.common
import qs.widgets.ControlCenter

// 28px circle button; destructive buttons need a confirm click while armed
Item {
  id: root

  required property string icon
  property string tooltip: ""
  property bool isDestructive: false
  property bool needsConfirm: false
  property bool isArmed: false
  readonly property bool isHovered: mouseArea.containsMouse

  signal activated

  implicitWidth: ConfigControlCenter.headerButtonSize
  implicitHeight: ConfigControlCenter.headerButtonSize

  StyledRect {
    anchors.fill: parent
    radius: width / 2
    color: {
      if (root.isDestructive) {
        return root.isHovered || root.isArmed ? Theme.options.red : Theme.addAlpha(Theme.options.red, 0.14);
      }
      if (root.isArmed) {
        return Theme.options.peach;
      }
      return root.isHovered ? Theme.options.surface1 : Theme.options.surface0;
    }
    scale: mouseArea.pressed ? 0.92 : 1

    Behavior on scale {
      NumberAnimation {
        duration: Styles.animation.duration
        easing.type: Styles.animation.easingType
      }
    }

    MaterialIcon {
      anchors.centerIn: parent
      icon: root.isArmed ? "check" : root.icon
      size: 16
      weight: Font.Normal
      color: {
        if (root.isDestructive) {
          return root.isHovered || root.isArmed ? Theme.options.crust : Theme.options.red;
        }
        if (root.isArmed) {
          return Theme.options.crust;
        }
        return root.isHovered ? Theme.options.text : Theme.options.subtext1;
      }
    }
  }

  Timer {
    id: armTimer

    interval: ConfigControlCenter.confirmTimeout
    onTriggered: root.isArmed = false
  }

  MouseArea {
    id: mouseArea

    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      if (root.needsConfirm && !root.isArmed) {
        root.isArmed = true;
        armTimer.restart();
        return;
      }
      root.isArmed = false;
      root.activated();
    }
  }
}
