import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets.VBar.config
import qs.widgets.VBar.modules.Hyprland

ColumnLayout {
  id: root

  required property bool isFocused

  spacing: ConfigVBar.modulesSpacing

  VHyprMonocle {
    Layout.alignment: Qt.AlignHCenter
  }

  VHyprSubmap {
    Layout.alignment: Qt.AlignHCenter
  }

  VHyprHarpoonCount {
    Layout.alignment: Qt.AlignHCenter
    tagPrefix: "harpoon-"
    excludedTagPrefix: "harpoon-scratchpad-"
    fgColor: Theme.options.blue
  }

  VHyprHarpoonCount {
    Layout.alignment: Qt.AlignHCenter
    tagPrefix: "harpoon-scratchpad-"
    fgColor: Theme.options.maroon
    icon: "󱡁 "
  }

  VHyprWsSpecialCount {
    Layout.alignment: Qt.AlignHCenter
    namespace: "scratchpads"
  }

  VHyprWsSpecialCount {
    Layout.alignment: Qt.AlignHCenter
    namespace: "tmpscratchpads"
    fgColor: Theme.options.red
  }

  VHyprTitle {
    Layout.alignment: Qt.AlignHCenter
    isFocused: root.isFocused
  }
}
