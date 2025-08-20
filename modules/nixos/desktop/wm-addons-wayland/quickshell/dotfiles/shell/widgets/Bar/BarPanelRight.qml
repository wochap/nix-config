import QtQuick

import qs.widgets.Bar.config

Item {
  id: root

  anchors.right: parent.right
  anchors.rightMargin: 0
  anchors.top: parent.top
  anchors.topMargin: ConfigBar.barPaddingY
  anchors.bottom: parent.bottom
  anchors.bottomMargin: ConfigBar.barPaddingY

  // 3. The wrapper's width is bound to the layout's needed width
  // width: theRowLayout.implicitWidth
}
