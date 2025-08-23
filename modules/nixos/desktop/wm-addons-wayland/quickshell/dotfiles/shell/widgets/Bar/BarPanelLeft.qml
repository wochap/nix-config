import QtQuick
import QtQuick.Layouts

import qs.widgets.Bar.config
import qs.widgets.Bar.modules.hyprland.HyprWorkspaces

RowLayout {
  id: root

  spacing: 0

  HyprWorkspaces {
    id: hyprWorkspaces

    Layout.fillHeight: true
  }
}
