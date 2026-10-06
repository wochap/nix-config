//@ pragma IconTheme Reversal-Extra
//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

// second entry point, run as its own resident instance
// (`quickshell -p .../shell/lock.qml`), shares the config, services and
// widgets of shell.qml
import Quickshell
import qs.config
import qs.widgets.Lock

ShellRoot {
  // a reload while locked would recreate SLockSession unlocked
  settings.watchFiles: false

  LazyLoader {
    active: Theme.ready
    component: Lock {}
  }
}
