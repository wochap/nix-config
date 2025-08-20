import Quickshell
import Quickshell.Wayland

import qs.config
import qs.widgets.Bar.config
import qs.widgets.Bar.modules.hyprland.HyprWorkspaces

PanelWindow {
  id: root

  required property ShellScreen modelData

  WlrLayershell.layer: WlrLayer.Bottom
  anchors {
    top: true
    left: true
    right: true
  }

  screen: root.modelData
  implicitHeight: ConfigBar.barHeight
  color: Theme.options.background

  BarPanelLeft {}
  BarPanelCenter {}
  BarPanelRight {}
}
