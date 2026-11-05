//@ pragma IconTheme Reversal-Extra
//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

// second entry point, run as its own resident instance
// (`quickshell -p .../shell/lock.qml`), shares the config, services and
// widgets of shell.qml
import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets.Lock

ShellRoot {
  // a reload while locked would recreate SLockSession unlocked
  settings.watchFiles: false

  // Preload wallpaper for each screen so it is decoded in Qt's pixmap cache
  Variants {
    model: Quickshell.screens

    Image {
      required property var modelData

      visible: false
      source: `file://${SWallpaper.pathFor(modelData.name)}`
      sourceSize.width: modelData.width
      sourceSize.height: modelData.height
      cache: true
    }
  }

  // Preload fallback wallpaper
  Image {
    visible: false
    source: `file://${SWallpaper.fallback}`
    cache: true
  }

  LazyLoader {
    active: Theme.ready
    component: Lock {}
  }
}
