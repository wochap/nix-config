import QtQuick
import qs.config
import qs.widgets.common

// Centered switcher surface: base · 1px surface0 · r8 · p12 · e2. Content is
// stacked in a column with a 10px gap. Clicks on the panel itself are
// swallowed so they never reach the scrim behind it.
Item {
  id: root

  default property alias content: column.data
  readonly property real padding: 12

  implicitWidth: column.implicitWidth + 2 * root.padding
  implicitHeight: column.implicitHeight + 2 * root.padding

  StyledRectangularShadow {
    target: background
    elevation: Styles.elevation.e2
  }

  StyledRect {
    id: background

    anchors.fill: parent
    radius: Styles.radius.windowRounding
    color: Theme.options.background
    border {
      width: 1
      color: Theme.options.borderSecondary
    }
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.AllButtons
  }

  Column {
    id: column

    x: root.padding
    y: root.padding
    spacing: 10
  }
}
