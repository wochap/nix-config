import QtQuick
import QtQuick.Layouts

import qs.widgets.Bar.config
import qs.widgets.Bar.modules.hyprland.HyprWorkspaces

RowLayout {
  id: root

  anchors {
    left: parent.left
    leftMargin: ConfigBar.barPaddingX
    top: parent.top
    topMargin: ConfigBar.barPaddingY
    bottom: parent.bottom
    bottomMargin: ConfigBar.barPaddingY
  }

  spacing: 0

  HyprWorkspaces {
    id: hyprWorkspaces

    Layout.fillHeight: true
  }
}
