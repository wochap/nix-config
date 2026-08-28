import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.services
import qs.services.SNotifications

PanelWindow {
  id: root

  Component.onDestruction: SNotifications.resetPopupHover()

  property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
  property var hyprlandMonitor: SHyprland.monitorsByName?.[focusedScreen?.name] ?? null
  property var focusedWorkspace: SHyprland.workspacesById?.[hyprlandMonitor?.activeWorkspace?.id] ?? null
  property var focusedClient: SHyprland.clientsByAddress?.[focusedWorkspace?.lastwindow] ?? null
  property bool isFocusedClientFullScreen: (focusedClient?.fullscreen ?? null) === 2

  WlrLayershell.namespace: "quickshell:notifications-popups"
  WlrLayershell.layer: WlrLayer.Overlay
  anchors {
    top: true
    bottom: true
    right: true
    left: true
  }
  screen: focusedScreen
  exclusionMode: isFocusedClientFullScreen ? ExclusionMode.Ignore : ExclusionMode.Normal
  exclusiveZone: 0
  color: "transparent"
  mask: Region {
    item: listview.contentItem
  }

  ListView {
    id: listview

    addDisplaced: Transition {
      id: addDisplacedTransition

      NumberAnimation {
        property: "y"
        duration: addDisplacedTransition.ViewTransition.item?.isEntering ? 0 : Styles.animation.duration
        easing.type: Styles.animation.easingType
      }
    }
    removeDisplaced: Transition {
      NumberAnimation {
        property: "y"
        duration: Styles.animation.duration
        easing.type: Styles.animation.easingType
      }
    }
    anchors {
      top: parent.top
      bottom: parent.bottom
      right: parent.right
      topMargin: 8
      rightMargin: anchors.topMargin
    }
    bottomMargin: anchors.topMargin
    implicitWidth: ConfigNotifications.notificationsPopupsWidth
    spacing: ConfigNotifications.notificationsSpacing
    clip: false
    // PERF: do granular updates with ScriptModel
    model: ScriptModel {
      values: SNotifications.popupList
    }
    delegate: NotificationPopupDelegate {
      slideDistance: listview.width
    }

    HoverHandler {
      onHoveredChanged: {
        SNotifications.arePopupsHovered = hovered;
      }
    }

  }
}
