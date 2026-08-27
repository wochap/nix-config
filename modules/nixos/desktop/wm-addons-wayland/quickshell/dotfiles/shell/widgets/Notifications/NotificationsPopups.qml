import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Qt5Compat.GraphicalEffects
import qs.config
import qs.services
import qs.services.SNotifications
import qs.widgets.common

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

  StyledListView {
    id: listview

    // Delegates own their entrance animation so rapid insertions cannot cancel
    // an add transition when an entering item becomes displaced.
    add: null
    // The delegate owns its removal animation so delayRemove can keep the
    // trailing item alive after the model's content height has shrunk.
    remove: null
    anchors {
      top: parent.top
      bottom: parent.bottom
      right: parent.right
      topMargin: 8
      rightMargin: anchors.topMargin
    }
    bottomMargin: anchors.topMargin
    implicitWidth: ConfigNotifications.notificationsPopupsWidth
    // Spacing is part of each delegate so it can collapse during removal.
    spacing: 0
    clip: false
    // PERF: do granular updates with ScriptModel
    model: ScriptModel {
      values: SNotifications.popupList
    }
    delegate: Item {
      id: popupDelegate

      required property int index
      required property SNotification modelData
      // ScriptModel can invalidate modelData while retaining a removed row.
      property SNotification retainedModelData: modelData
      property real popupOffset: 0
      property real layoutHeight: popupItem.implicitHeight + ConfigNotifications.notificationsSpacing
      property ParallelAnimation popupAddAnimation: ParallelAnimation {
        NumberAnimation {
          target: popupDelegate
          property: "popupOffset"
          to: 0
          duration: Styles.animation.duration
          easing.type: Styles.animation.easingType
        }
        NumberAnimation {
          target: popupDelegate
          property: "opacity"
          to: 1
          duration: Styles.animation.duration
          easing.type: Styles.animation.easingType
        }
        onStopped: {
          if (!popupRemoveAnimation.running) {
            popupDelegate.popupOffset = 0;
            popupDelegate.opacity = 1;
          }
        }
      }
      property ParallelAnimation popupRemoveAnimation: ParallelAnimation {
        NumberAnimation {
          target: popupDelegate
          property: "popupOffset"
          to: listview.width
          duration: Styles.animation.duration
          easing.type: Styles.animation.easingType
        }
        NumberAnimation {
          target: popupDelegate
          property: "layoutHeight"
          to: 0
          duration: Styles.animation.duration
          easing.type: Styles.animation.easingType
        }
        NumberAnimation {
          target: popupDelegate
          property: "opacity"
          to: 0
          duration: Styles.animation.duration
          easing.type: Styles.animation.easingType
        }
        onStopped: {
          const notification = popupDelegate.retainedModelData;
          if (notification?.isPopupExiting ?? false)
            SNotifications.finalizePopupRemoval(notification.notificationId);
        }
      }

      function startRemoval() {
        if (popupRemoveAnimation.running)
          return;

        popupAddAnimation.stop();
        popupRemoveAnimation.start();
      }

      opacity: 0
      Component.onCompleted: {
        popupDelegate.retainedModelData = popupDelegate.modelData;
        if (popupDelegate.retainedModelData.isPopupExiting)
          popupDelegate.startRemoval();
      }
      ListView.onAdd: {
        popupDelegate.popupOffset = listview.width;
        popupDelegate.opacity = 0;
        popupAddAnimation.start();
      }
      ListView.delayRemove: popupRemoveAnimation.running
      ListView.onRemove: {
        // Service-managed removals finish before changing the model. This is
        // a safety fallback for an unexpected direct model removal.
        if (popupDelegate.popupOffset < listview.width) {
          popupDelegate.startRemoval();
        }
      }

      z: popupRemoveAnimation.running ? -1 : (popupAddAnimation.running ? 1 : 0)
      implicitHeight: layoutHeight
      anchors.left: parent?.left
      anchors.right: parent?.right
      transform: Translate {
        x: popupDelegate.popupOffset
      }

      NotificationItem {
        id: popupItem

        index: popupDelegate.index
        modelData: popupDelegate.retainedModelData
        isPopup: true
        height: implicitHeight
        anchors {
          top: parent.top
          left: parent.left
          right: parent.right
        }
      }

      Connections {
        target: popupDelegate.retainedModelData

        function onIsPopupExitingChanged() {
          if (popupDelegate.retainedModelData.isPopupExiting)
            popupDelegate.startRemoval();
        }
      }
    }

    HoverHandler {
      onHoveredChanged: {
        SNotifications.arePopupsHovered = hovered;
      }
    }

  }
}
