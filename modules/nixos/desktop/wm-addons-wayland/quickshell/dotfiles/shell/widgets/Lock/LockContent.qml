pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import qs.config
import qs.services
import qs.widgets.common
import qs.widgets.Lock

// content of one output's lock surface, see design/project/LockScreen.dc.html
// The output focused at lock time gets the input, strip, dock and panels,
// the others only the clock.
FocusScope {
  id: root

  required property var screen
  readonly property string screenName: root.screen?.name ?? ""
  readonly property var primaryScreen: Quickshell.screens.find(s => s.name === SLockSession.focusedScreen) ?? Quickshell.screens[0] ?? null
  readonly property bool isPrimary: root.primaryScreen === null || root.screenName === root.primaryScreen.name
  // bt | media | power | ""
  property string openPanel: ""
  // restart | shutdown | logout | "", opened from the power panel
  property string confirmAction: ""
  property bool isHintVisible: false

  function focusInput() {
    primaryLoader.item?.focusInput();
  }

  function focusPanel() {
    primaryLoader.item?.focusPanel();
  }

  function togglePanel(panel) {
    if (panel === "media" && !SMpris.available) {
      return;
    }
    root.confirmAction = "";
    root.openPanel = root.openPanel === panel ? "" : panel;
    if (root.openPanel === "") {
      root.focusInput();
    }
  }

  function closePanel() {
    root.confirmAction = "";
    root.openPanel = "";
    root.focusInput();
  }

  // same commands as SControlCenter.runSessionAction
  function runPowerAction(action) {
    const commands = {
      sleep: "systemctl suspend",
      restart: "systemctl reboot",
      shutdown: "systemctl poweroff --check-inhibitors=no",
      logout: "uwsm stop"
    };
    root.closePanel();
    if (commands[action]) {
      Quickshell.execDetached(["bash", "-c", commands[action]]);
    }
  }

  function requestPowerAction(action) {
    if (action === "sleep") {
      root.runPowerAction(action);
    } else {
      root.confirmAction = action;
    }
  }

  // shortcuts that work from the field and from any panel
  function handleKey(event) {
    SLockSession.poke();
    if (!root.isPrimary) {
      root.showHint();
      return;
    }
    if (SLockSession.isSuccess) {
      return;
    }
    if (event.modifiers & Qt.AltModifier) {
      const panels = {
        [Qt.Key_B]: "bt",
        [Qt.Key_M]: "media",
        [Qt.Key_P]: "power"
      };
      if (panels[event.key]) {
        root.togglePanel(panels[event.key]);
        event.accepted = true;
      }
    } else if (event.key === Qt.Key_Escape) {
      if (root.confirmAction !== "") {
        root.confirmAction = "";
        Qt.callLater(root.focusPanel);
      } else if (root.openPanel !== "") {
        root.closePanel();
      }
      event.accepted = true;
    }
  }

  function showHint() {
    root.isHintVisible = true;
    hintTimer.restart();
  }

  // the arrow points toward the focused output
  function hintIcon() {
    const primary = root.primaryScreen;
    const screen = root.screen;
    if (!primary || !screen) {
      return "arrow_back";
    }
    if (primary.x + primary.width <= screen.x) {
      return "arrow_back";
    }
    if (primary.x >= screen.x + screen.width) {
      return "arrow_forward";
    }
    return primary.y < screen.y ? "arrow_upward" : "arrow_downward";
  }

  focus: true

  onOpenPanelChanged: {
    if (root.openPanel === "media" && !SMpris.available) {
      root.openPanel = "";
    }
  }

  Connections {
    target: SMpris

    function onAvailableChanged() {
      if (!SMpris.available && root.openPanel === "media") {
        root.closePanel();
      }
    }
  }

  Timer {
    id: hintTimer

    interval: ConfigLock.hintDuration
    onTriggered: root.isHintVisible = false
  }

  FocusScope {
    id: content

    anchors.fill: parent
    focus: true

    Keys.onPressed: event => root.handleKey(event)

    // hold, then fade the whole surface before the lock drops
    SequentialAnimation {
      running: SLockSession.isSuccess
      onStopped: {
        if (!SLockSession.isSuccess) {
          content.opacity = 1;
        }
      }

      PauseAnimation {
        duration: SLockSession.successHold
      }
      NumberAnimation {
        target: content
        property: "opacity"
        to: 0
        duration: SLockSession.successFade
        easing.type: Easing.OutCubic
      }
    }

    Image {
      id: wallpaper

      anchors.fill: parent
      visible: false
      source: `file://${SWallpaper.pathFor(root.screenName)}`
      sourceSize.width: root.width
      sourceSize.height: root.height
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      cache: false
      onStatusChanged: {
        if (wallpaper.status === Image.Error && wallpaper.source.toString() !== `file://${SWallpaper.fallback}`) {
          wallpaper.source = `file://${SWallpaper.fallback}`;
        }
      }
    }

    // no blur, stays cheap on every output
    MultiEffect {
      anchors.fill: parent
      visible: wallpaper.status === Image.Ready
      source: wallpaper
      saturation: ConfigLock.wallpaperSaturation
      brightness: ConfigLock.wallpaperBrightness
    }

    Rectangle {
      anchors.fill: parent
      color: Theme.options.crust
      opacity: ConfigLock.scrimOpacity
    }

    HoverHandler {
      onPointChanged: {
        SLockSession.poke();
        if (!root.isPrimary) {
          root.showHint();
        }
      }
    }

    TapHandler {
      onTapped: {
        SLockSession.poke();
        if (!root.isPrimary) {
          root.showHint();
        } else if (root.confirmAction === "" && root.openPanel !== "") {
          root.closePanel();
        } else if (root.confirmAction === "") {
          root.focusInput();
        }
      }
    }

    // secondary: clock only, centred
    LockClock {
      anchors.centerIn: parent
      visible: !root.isPrimary
      isHintVisible: root.isHintVisible
      hintIcon: root.hintIcon()
    }

    Loader {
      id: primaryLoader

      anchors.fill: parent
      active: root.isPrimary
      focus: true

      sourceComponent: FocusScope {
        id: primary

        readonly property real dimmedOpacity: SLockSession.isIdleDimmed ? ConfigLock.dimOpacity : 1

        function focusInput() {
          input.focusInput();
        }

        function focusPanel() {
          slot.focusPanel();
        }

        anchors.fill: parent
        focus: true

        LockIdentity {
          anchors {
            top: parent.top
            right: parent.right
            margins: ConfigLock.edgeMargin
          }
          opacity: primary.dimmedOpacity

          Behavior on opacity {
            NumberAnimation {
              duration: Styles.animation.duration
              easing.type: Styles.animation.easingType
            }
          }
        }

        // clock top at 332 on 1080p, rows below the field only grow downward
        Column {
          anchors.horizontalCenter: parent.horizontalCenter
          y: Math.round(parent.height * ConfigLock.clockTop / 1080)
          spacing: 40

          LockClock {
            anchors.horizontalCenter: parent.horizontalCenter
            opacity: primary.dimmedOpacity

            Behavior on opacity {
              NumberAnimation {
                duration: Styles.animation.duration
                easing.type: Styles.animation.easingType
              }
            }
          }

          LockInput {
            id: input

            anchors.horizontalCenter: parent.horizontalCenter
            focus: true
            opacity: SLockSession.isIdleDimmed ? 0 : 1
            onKeyPressed: event => {
              root.handleKey(event);
              if (!event.accepted && event.key === Qt.Key_Escape) {
                event.accepted = true;
              }
            }

            Behavior on opacity {
              NumberAnimation {
                duration: Styles.animation.duration
                easing.type: Styles.animation.easingType
              }
            }
          }
        }

        LockStatusStrip {
          anchors {
            left: parent.left
            bottom: parent.bottom
            margins: ConfigLock.edgeMargin
          }
          isMediaOpen: root.openPanel === "media"
          opacity: primary.dimmedOpacity
          onMediaRequested: root.togglePanel("media")

          Behavior on opacity {
            NumberAnimation {
              duration: Styles.animation.duration
              easing.type: Styles.animation.easingType
            }
          }
        }

        LockDock {
          anchors {
            right: parent.right
            bottom: parent.bottom
            margins: ConfigLock.edgeMargin
          }
          openPanel: root.openPanel
          opacity: primary.dimmedOpacity
          onToggled: panel => root.togglePanel(panel)

          Behavior on opacity {
            NumberAnimation {
              duration: Styles.animation.duration
              easing.type: Styles.animation.easingType
            }
          }
        }

        LockPanelSlot {
          id: slot

          anchors {
            right: parent.right
            bottom: parent.bottom
            rightMargin: ConfigLock.edgeMargin
            bottomMargin: ConfigLock.panelBottom
          }
          // the confirm dialog replaces the power panel, the dock keeps it open
          panel: root.confirmAction !== "" ? "" : root.openPanel
          onCloseRequested: root.closePanel()
          onPowerActionRequested: action => root.requestPowerAction(action)
        }

        // confirm layer over everything
        Rectangle {
          anchors.fill: parent
          visible: confirmLoader.active
          color: Theme.options.crust
          opacity: ConfigLock.confirmScrimOpacity

          MouseArea {
            anchors.fill: parent
          }
        }

        Loader {
          id: confirmLoader

          anchors.centerIn: parent
          active: root.confirmAction !== ""
          focus: active

          sourceComponent: ConfirmDialog {
            id: dialog

            action: root.confirmAction
            opacity: 0
            scale: 0.98
            Component.onCompleted: {
              forceActiveFocus();
              enterAnimation.start();
            }
            onConfirmed: root.runPowerAction(root.confirmAction)
            onCanceled: {
              root.confirmAction = "";
              Qt.callLater(root.focusPanel);
            }

            ParallelAnimation {
              id: enterAnimation

              NumberAnimation {
                target: dialog
                properties: "opacity,scale"
                to: 1
                duration: Styles.animation.duration
                easing.type: Styles.animation.easingType
              }
            }
          }
        }
      }
    }
  }
}
