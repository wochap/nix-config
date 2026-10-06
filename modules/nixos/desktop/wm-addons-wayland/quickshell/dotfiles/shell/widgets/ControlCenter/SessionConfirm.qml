import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets.Lock

// full screen dimmed overlay with the lock screen countdown confirm, opened by
// the control center header buttons
PanelWindow {
  id: root

  // ConfirmDialog speaks restart | shutdown | logout
  readonly property string dialogAction: ({
      logout: "logout",
      reboot: "restart",
      poweroff: "shutdown"
    })[SControlCenter.confirmAction] ?? ""

  screen: Quickshell.screens.find(s => s.name === SControlCenter.confirmScreenName) ?? null
  WlrLayershell.namespace: "quickshell:session-confirm"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
  anchors {
    top: true
    left: true
    bottom: true
    right: true
  }
  exclusionMode: ExclusionMode.Ignore
  color: "transparent"

  Rectangle {
    id: scrim

    anchors.fill: parent
    color: Theme.addAlpha(Theme.options.crust, ConfigLock.confirmScrimOpacity)
    opacity: 0

    // clicking outside cancels, the safe way out
    MouseArea {
      anchors.fill: parent
      onClicked: SControlCenter.cancelSessionAction()
    }
  }

  ConfirmDialog {
    id: dialog

    anchors.centerIn: parent
    action: root.dialogAction
    origin: "logind · from control center"
    focus: true
    opacity: 0
    scale: 0.98
    Component.onCompleted: forceActiveFocus()
    onConfirmed: SControlCenter.runSessionAction(SControlCenter.confirmAction)
    onCanceled: SControlCenter.cancelSessionAction()
  }

  ParallelAnimation {
    running: true

    NumberAnimation {
      target: scrim
      property: "opacity"
      to: 1
      duration: Styles.animation.duration
      easing.type: Styles.animation.easingType
    }
    NumberAnimation {
      target: dialog
      properties: "opacity,scale"
      to: 1
      duration: Styles.animation.duration
      easing.type: Styles.animation.easingType
    }
  }
}
