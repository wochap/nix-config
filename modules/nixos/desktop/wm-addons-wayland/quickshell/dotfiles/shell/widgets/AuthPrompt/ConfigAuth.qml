pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config

// tokens from design/project/AuthParts.dc.html
Singleton {
  id: root

  readonly property bool isDark: Theme.options.flavour !== "latte"

  // stock latte lavender is ~2.9:1 on base, so fills and focus use a deepened one
  readonly property color ink: root.isDark ? Theme.options.lavender : "#3f53d9"
  readonly property color inkHover: root.isDark ? "#c6cdfe" : "#5164e0"
  readonly property color inkPressed: root.isDark ? "#9ea9f2" : "#3343bd"
  readonly property color onInk: Theme.options.base
  readonly property color edge: Theme.options.lavender
  readonly property color fieldBorder: root.isDark ? Theme.options.overlay0 : Theme.options.overlay2
  readonly property color placeholder: root.isDark ? Theme.options.overlay2 : Theme.options.subtext0
  readonly property color subtext: root.isDark ? Theme.options.subtext0 : Theme.options.subtext1

  readonly property real dialogWidth: 440
  readonly property real dialogPadding: 20
  readonly property real dialogRadius: 12
  readonly property real controlRadius: 8
  readonly property real chipRadius: 6
  readonly property real smallRadius: 4
  readonly property real badgeSize: 32
  readonly property real fieldHeight: 36
  readonly property real buttonHeight: 32
  readonly property real checkboxSize: 16
  readonly property real detailsLabelWidth: 76
  readonly property real badgeTint: 0.16
  readonly property real disabledOpacity: 0.55
  readonly property real scrimOpacity: 0.6

  readonly property int titleSize: 15
  readonly property int bodySize: 13
  readonly property int metaSize: 12
  readonly property int keycapSize: 11
  readonly property int hiddenTextSize: 15

  // spinner shows only when verifying takes longer, avoids flicker
  readonly property int spinnerDelay: 150

  // palette name (peach, mauve, ...) to color
  function tint(name) {
    return Theme.options[name] ?? Theme.options.text;
  }
}
