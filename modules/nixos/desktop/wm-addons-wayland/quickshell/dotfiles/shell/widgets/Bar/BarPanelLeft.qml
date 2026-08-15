import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets.Bar.config
import qs.widgets.Bar.modules
import qs.widgets.Bar.modules.Hyprland
import qs.widgets.Bar.modules.Hyprland.HyprWorkspaces

RowLayout {
  id: root

  required property bool isFocused

  spacing: ConfigBar.modulesSpacing

  HyprMonocle {
    Layout.fillHeight: true
  }

  HyprWsSpecialCount {
    Layout.fillHeight: true
    namespace: "scratchpads"
  }

  HyprWsSpecialCount {
    Layout.fillHeight: true
    namespace: "tmpscratchpads"
    fgColor: Theme.options.red
  }

  HyprHarpoonCount {
    Layout.fillHeight: true
    tagPrefix: "harpoon-"
    excludedTagPrefix: "harpoon-scratchpad-"
    fgColor: Theme.options.blue
  }

  HyprHarpoonCount {
    Layout.fillHeight: true
    tagPrefix: "harpoon-scratchpad-"
    fgColor: Theme.options.maroon
    icon: "󱡁 "
  }

  HyprSubmap {
    Layout.fillHeight: true
  }

  HyprTitle {
    Layout.fillHeight: true
    Layout.leftMargin: -1
    opacity: root.isFocused ? 1 : 0.5
  }
}
