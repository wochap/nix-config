import QtQuick
import qs.config
import qs.Woints

// Clickable bar chip: transparent → surface1 on hover, surface0 + 1px primary
// border while `active` (its popover is open). Callers set size, radius and
// content; content children are non-interactive so clicks reach the MouseArea.
Rectangle {
  id: root

  property bool active: false
  property color hoverColor: Theme.options.surface1
  property color activeColor: Theme.options.surface0
  property bool animateColor: true
  property string accessibleName: ""
  property string hintLabel: root.accessibleName
  readonly property bool hovered: hoverHandler.hovered

  signal clicked

  color: root.hovered ? root.hoverColor : root.active ? root.activeColor : "transparent"
  border.width: root.active ? 1 : 0
  border.color: Theme.options.primary

  Behavior on color {
    enabled: root.animateColor
    animation: Styles.animations.colorAnimation.createObject(this)
  }

  HoverHandler {
    id: hoverHandler
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton
    onClicked: root.clicked()
    Accessible.role: Accessible.Button
    Accessible.name: root.accessibleName
    Accessible.checkable: true
    Accessible.checked: root.active
    Accessible.onPressAction: root.clicked()

    Hintable {
      label: root.hintLabel
      onActivated: root.clicked()
    }
  }
}
