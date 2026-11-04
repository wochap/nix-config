import QtQuick
import QtQuick.Layouts
import qs.widgets.VBar.config
import qs.widgets.VBar.modules.Hyprland.VHyprWorkspaces

ColumnLayout {
  id: root

  property bool isFocused: true

  spacing: ConfigVBar.modulesSpacing

  VHyprWorkspaces {
    id: hyprWorkspaces

    Layout.alignment: Qt.AlignHCenter
  }
}
