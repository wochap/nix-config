import Quickshell.Io
import QtQuick
import QtQuick.Layouts

import qs.config
import qs.widgets.Bar.config
import qs.widgets.Bar.modules
import qs.widgets.Bar.modules.hyprland
import qs.widgets.Bar.modules.hyprland.HyprWorkspaces

RowLayout {
  id: root

  spacing: ConfigBar.modulesSpacing

  HyprWsSpecialCount {
    Layout.fillHeight: true
    namespace: "scratchpads"
  }

  HyprWsSpecialCount {
    Layout.fillHeight: true
    namespace: "tmpscratchpads"
    fgColor: Theme.options.red
  }
}
