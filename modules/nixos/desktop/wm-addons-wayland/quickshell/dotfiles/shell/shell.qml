//@ pragma IconTheme Reversal-Extra
//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

import Quickshell
import Quickshell.Io
import QtQuick

import qs.services.SNotifications
import qs.config
import qs.widgets
import qs.widgets.Bar
import qs.widgets.Notifications

ShellRoot {
  id: root

  property bool renderBar: true
  property bool renderBacklight: true
  property bool renderOutput: true
  property bool renderCapslock: true
  property bool renderOutputMuted: true
  property bool renderInputMuted: true
  property bool renderNotifications: false

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

  LazyLoader {
    active: root.renderCapslock && Theme.ready
    component: Capslock {}
  }

  LazyLoader {
    active: root.renderOutputMuted && Theme.ready
    component: OutputMuted {}
  }

  LazyLoader {
    active: root.renderInputMuted && Theme.ready
    component: InputMuted {}
  }

  LazyLoader {
    active: root.renderNotifications && Theme.ready && SNotifications.isReady
    component: Notifications {}
  }

  IpcHandler {
    target: "bar"

    function toggle() {
      root.renderBar = !root.renderBar;
    }
  }
}
