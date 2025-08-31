import QtQuick
import QtQuick.Layouts
import qs.widgets.Bar.config
import qs.widgets.Bar.modules.hyprland.HyprWorkspaces

RowLayout {
  id: root

  spacing: ConfigBar.modulesSpacing

  HyprWorkspaces {
    id: hyprWorkspaces

    Layout.fillHeight: true
  }
}
