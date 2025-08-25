//@ pragma IconTheme Reversal-Extra
//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

import Quickshell

import qs.config
import qs.widgets
import qs.widgets.Bar

ShellRoot {
  id: root

  property bool renderBar: true
  property bool renderBacklight: true
  property bool renderOutput: true

  LazyLoader {
    active: root.renderBar && Theme.ready
    component: Bar {}
  }

  LazyLoader {
    active: root.renderBacklight && Theme.ready
    component: Backlight {}
  }

  LazyLoader {
    active: root.renderOutput && Theme.ready
    component: Output {}
  }
}
