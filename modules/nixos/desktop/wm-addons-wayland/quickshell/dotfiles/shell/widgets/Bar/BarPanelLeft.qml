import QtQuick

import qs.widgets.Bar.config
import qs.widgets.Bar.modules.hyprland.HyprWorkspaces

Item {
  id: root

  anchors.left: parent.left
  anchors.leftMargin: ConfigBar.barPaddingX
  anchors.top: parent.top
  anchors.topMargin: ConfigBar.barPaddingY
  anchors.bottom: parent.bottom
  anchors.bottomMargin: ConfigBar.barPaddingY

  // 3. The wrapper's width is bound to the layout's needed width
  width: hyprWorkspaces.implicitWidth

  HyprWorkspaces {
    id: hyprWorkspaces

    anchors.fill: parent
  }
}
