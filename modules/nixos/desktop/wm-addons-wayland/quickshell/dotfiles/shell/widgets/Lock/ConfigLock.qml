pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config
import qs.widgets.AuthPrompt

// tokens from design/project/LockScreen.dc.html, the auth flow timings live
// in SLockSession
Singleton {
  id: root

  readonly property bool isDark: Theme.options.flavour !== "latte"

  // the lock uses mauve where auth dialogs use lavender
  readonly property color ink: root.isDark ? "#cba6f7" : "#8839ef"
  readonly property color inkHover: root.isDark ? "#d9bdfa" : "#9a52f2"
  readonly property color inkPressed: root.isDark ? "#b48ef0" : "#7524d9"

  // --sub, --ov and --field-br of the design, shared with the auth dialogs
  readonly property color subtext: ConfigAuth.subtext
  readonly property color overlay: ConfigAuth.placeholder
  readonly property color fieldBorder: ConfigAuth.fieldBorder

  // wallpaper treatment, no blur to stay cheap on every output
  readonly property real wallpaperSaturation: root.isDark ? -0.45 : -0.5
  readonly property real wallpaperBrightness: root.isDark ? -0.3 : 0.15
  readonly property real scrimOpacity: root.isDark ? 0.5 : 0.6
  readonly property real confirmScrimOpacity: 0.6
  readonly property real dimOpacity: 0.4
  readonly property real disabledOpacity: 0.45
  // accent fill / inset line of open dock buttons and pills
  readonly property real openTint: 0.16
  readonly property real openLine: 0.55

  readonly property real edgeMargin: 32
  readonly property real clockTop: 332
  readonly property real clockSize: 112
  readonly property real dateSize: 22
  readonly property real fieldWidth: 360
  readonly property real railHeight: 40
  readonly property real pillHeight: 28
  readonly property real panelBottom: 80
  readonly property real panelWidth: 360
  readonly property real bluetoothPanelHeight: 440
  readonly property real powerPanelWidth: 260
  readonly property real confirmWidth: 400
  readonly property real radius: 8
  readonly property real rowRadius: 6

  readonly property int hintDuration: 4000
  readonly property int tooltipDelay: 400
  readonly property int scanDuration: 30000
  readonly property int connectTimeout: 15000
  readonly property int confirmSeconds: 10
}
