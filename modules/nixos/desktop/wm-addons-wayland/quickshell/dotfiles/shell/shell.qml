//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

import Quickshell

import qs.config
import qs.widgets.Bar

ShellRoot {
  id: root

  property bool renderBar: true

  LazyLoader {
    active: renderBar && Theme.ready
    component: Bar {}
  }
}
