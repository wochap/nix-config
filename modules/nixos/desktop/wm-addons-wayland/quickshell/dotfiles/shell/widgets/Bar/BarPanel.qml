import Quickshell

import qs.config
import qs.widgets.Bar.modules.hyprland

PanelWindow {
  id: root

  required property ShellScreen modelData

  screen: root.modelData
  anchors {
    top: true
    left: true
    right: true
  }
  implicitHeight: 40

  color: Theme.options.background

  HyprWorkspaces {}
}
