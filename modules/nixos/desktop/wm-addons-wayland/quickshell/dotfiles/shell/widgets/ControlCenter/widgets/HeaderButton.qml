import QtQuick
import qs.config
import qs.widgets.common
import qs.widgets.ControlCenter
import qs.Woints

// 28px circle button; buttons with `needsConfirm` arm on the first click,
// grow into a red "Label?" pill and only run on a second click while armed
Item {
  id: root

  required property string icon
  property string tooltip: ""
  property bool isDestructive: false
  property bool needsConfirm: false
  property bool isArmed: false
  // time the button armed, a confirm click must come after armGuard ms so a
  // double click can't arm and confirm in one go
  property real armedAt: 0
  readonly property int armGuard: 400
  readonly property bool isHovered: mouseArea.containsMouse
  readonly property bool isRed: root.isDestructive || root.isArmed

  signal activated
  // emitted when the button arms, so siblings can disarm
  signal armed

  function disarm() {
    root.isArmed = false;
    armTimer.stop();
  }

  function press() {
    if (root.needsConfirm && !root.isArmed) {
      root.isArmed = true;
      root.armedAt = Date.now();
      armTimer.restart();
      armProgressAnimation.restart();
      root.armed();
      return;
    }
    if (root.needsConfirm && Date.now() - root.armedAt < root.armGuard) {
      return;
    }
    root.disarm();
    root.activated();
  }

  implicitWidth: root.isArmed ? armedRow.implicitWidth + 20 : ConfigControlCenter.headerButtonSize
  implicitHeight: ConfigControlCenter.headerButtonSize

  Behavior on implicitWidth {
    NumberAnimation {
      duration: Styles.animation.duration
      easing.type: Styles.animation.easingType
    }
  }

  StyledRect {
    anchors.fill: parent
    radius: height / 2
    color: {
      if (root.isArmed) {
        return root.isHovered ? Theme.options.maroon : Theme.options.red;
      }
      if (root.isDestructive) {
        return root.isHovered ? Theme.options.red : Theme.addAlpha(Theme.options.red, 0.14);
      }
      return root.isHovered ? Theme.options.surface1 : Theme.options.surface0;
    }
    scale: mouseArea.pressed ? 0.92 : 1
    clip: true

    Behavior on scale {
      NumberAnimation {
        duration: Styles.animation.duration
        easing.type: Styles.animation.easingType
      }
    }

    Row {
      id: armedRow

      anchors.centerIn: parent
      spacing: 4

      SystemIcon {
        enableColoriser: true
        anchors.verticalCenter: parent.verticalCenter
        icon: root.icon
        size: Styles.font.pixelSize.hugeass
        color: {
          if (root.isArmed) {
            return Theme.options.crust;
          }
          if (root.isDestructive) {
            return root.isHovered ? Theme.options.crust : Theme.options.red;
          }
          return root.isHovered ? Theme.options.text : Theme.options.subtext1;
        }
      }

      StyledText {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.isArmed
        text: `${root.tooltip}?`
        color: Theme.options.crust
        font.pixelSize: Styles.font.pixelSize.small
        font.weight: Font.Medium
      }
    }

    // remaining confirm time
    Rectangle {
      anchors {
        left: parent.left
        bottom: parent.bottom
      }
      height: 2
      width: parent.width * armProgress.value
      visible: root.isArmed
      color: Theme.options.crust
      opacity: 0.5
    }
  }

  QtObject {
    id: armProgress

    property real value: 0
  }

  NumberAnimation {
    id: armProgressAnimation

    target: armProgress
    property: "value"
    from: 1
    to: 0
    duration: ConfigControlCenter.confirmTimeout
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
    onClicked: root.press()
    Accessible.role: Accessible.Button
    Accessible.name: root.isArmed ? `Confirm ${root.tooltip}` : root.tooltip
    Accessible.onPressAction: root.press()

    Hintable {
      label: mouseArea.Accessible.name
      onActivated: root.press()
    }
  }
}
